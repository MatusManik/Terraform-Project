# COMPUTE OPTIMIZED GAME SERVERS
# Deploys 3 compute-optimized EC2 instances in a public subnet for game processing
resource "aws_instance" "game_server_compute_optimized" {
    count = 3

    ami                  = var.ami_id
    instance_type        = "c5.large"
    subnet_id            = aws_subnet.public_subnet_two.id
    key_name             = aws_key_pair.my_key_pair_for_ec2.key_name
    vpc_security_group_ids       = [aws_security_group.game_server_compute_optimized_sg.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_s3_access_instance_profile.name

    tags = {
        Name = "Game-Server-Compute-Optimized-${count.index + 1}"
        Type = "Compute Optimized"
    }
}

# NOSQL DATABASE CLUSTER
# Deploys 2 storage-optimized instances in a private subnet for database security
resource "aws_instance" "nosql_db_cluster" {
    count = 2

    ami                  = var.ami_id
    instance_type        = "i3.large"
    subnet_id            = aws_subnet.private_subnet_one.id
    key_name             = aws_key_pair.my_key_pair_for_ec2.key_name
    vpc_security_group_ids = [aws_security_group.nosql_db_cluster_sg.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_s3_access_instance_profile.name

    tags = {
        Name = "Game-NoSQL-Cluster-${count.index + 1}"
        Type = "Storage Optimized"
    }
}

# LAUNCH TEMPLATE
# Defines the base EC2 configuration used by the Auto Scaling Group
resource "aws_launch_template" "web_server_template" {
    name                   = "web-server-template"
    image_id               = var.ami_id
    instance_type          = "t3.micro"
    key_name               = aws_key_pair.my_key_pair_for_ec2.key_name
    vpc_security_group_ids = [aws_security_group.web_server_general_purpose_sg.id]

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_s3_access_instance_profile.name
    }

    tag_specifications {
        resource_type = "instance"
        
        tags = {
            Name = "Web-Server-General-Purpose"
            Type = "General Purpose"
        }
    }
}

# AUTO SCALING GROUP (ASG)
# Dynamically manages web server instances across multiple public subnets 
# to ensure high availability and balance load
resource "aws_autoscaling_group" "web_server_asg" {
    name = "web-server-auto-scaling-group"

    vpc_zone_identifier = [
        aws_subnet.public_subnet_one.id,
        aws_subnet.public_subnet_two.id
    ]
    
    min_size         = 2
    desired_capacity = 2
    max_size         = 6

    # Connects instances to the Application Load Balancer target group
    target_group_arns = [
        aws_lb_target_group.web_target_group.arn
    ]

    launch_template {
        id      = aws_launch_template.web_server_template.id
        version = "$Latest"
    }

    health_check_type         = "ALB"
    health_check_grace_period = 120

    tag {
        key                 = "Name"
        value               = "Web-Server-General-Purpose"
        propagate_at_launch = true
    }

    tag {
        key                 = "Type"
        value               = "General Purpose"
        propagate_at_launch = true
    }
}

# SCALING POLICIES
# Scale-out policy: Adds 1 instance when triggered (e.g., high traffic)
resource "aws_autoscaling_policy" "scale_out_policy" {
    name                   = "scale-out-policy"
    autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = 1
    cooldown               = 300
}

# Scale-in policy: Removes 1 instance when traffic decreases
resource "aws_autoscaling_policy" "scale_in_policy" {
    name                   = "scale-in-policy"
    autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = -1
    cooldown               = 300
}