# EC2 KEY PAIR
# Imports the local public SSH key for EC2 instance access
resource "aws_key_pair" "my_key_pair_for_ec2" {
    key_name   = "my-key-pair"
    public_key = file("./keys/my-key-pair.pub")
}

# NETWORK ACCESS CONTROL LIST (NACL)
# Subnet-level firewall rules for public subnets
resource "aws_network_acl" "acl_of_my_vpc" {
    vpc_id = aws_vpc.main_vpc.id
    subnet_ids = [
        aws_subnet.public_subnet_one.id,
        aws_subnet.public_subnet_two.id
    ]

    # Inbound: Allow HTTPS web traffic
    ingress {
        rule_no    = 100
        action     = "allow"
        protocol   = "tcp"
        from_port  = 443
        to_port    = 443
        cidr_block = "0.0.0.0/0"
    }

    ingress {
        rule_no    = 105
        action     = "allow"
        protocol   = "tcp"
        from_port  = 80
        to_port    = 80
        cidr_block = "0.0.0.0/0"
    }

    ingress {
        rule_no    = 110
        action     = "allow"
        protocol   = "tcp"
        from_port  = 22
        to_port    = 22
        cidr_block = "${var.admin_ip}"
    }

    # Outbound: Allow responses to clients on ephemeral ports
    egress {
        rule_no    = 100
        action     = "allow"
        protocol   = "tcp"
        from_port  = 1024
        to_port    = 65535
        cidr_block = "0.0.0.0/0"
    }
}

# APPLICATION LOAD BALANCER SECURITY GROUP
# Controls public entry traffic to the Application Load Balancer
resource "aws_security_group" "alb_security_group" {
    name        = "alb-Security-Group"
    description = "Security group for Application Load Balancer which allows SSH, HTTP and HTTPS network traffic"
    vpc_id      = aws_vpc.main_vpc.id

    # Allow inbound HTTPS from anywhere
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow inbound HTTP from anywhere
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow inboud SSH from Admin IP
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${var.admin_ip}"]
    }

    # Allow all outbound traffic from ALB
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# WEB SERVER SECURITY GROUP
# Controls traffic for general-purpose web servers
resource "aws_security_group" "web_server_general_purpose_sg" {
    name        = "web-server-general-purpose-sg"
    description = "Security group for general purpose web servers which allows just SSH, HTTP and HTTPS traffic"
    vpc_id      = aws_vpc.main_vpc.id

    # Restrict SSH access to admin IP only
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.admin_ip]
    }

    # Allow HTTPS traffic originating ONLY from the ALB Security Group
    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        security_groups = [aws_security_group.alb_security_group.id]
    }

    # Allow HTTP traffic originating ONLY from the ALB Security Group
    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.alb_security_group.id]
    }

    # Allow all outbound traffic
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# GAME SERVER SECURITY GROUP
resource "aws_security_group" "game_server_compute_optimized_sg" {
  name        = "game-server-compute-optimized-sg"
  description = "Security group for compute optimized game servers which allows just SSH and game client traffic"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow incoming UDP traffic from anywhere for game clients
  ingress {
    description = "Game client traffic"
    from_port   = 7777
    to_port     = 7777
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access from a specific management IP address
  ingress {
    description = "SSH access for admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  # Allow all outbound traffic from the game servers to the internet
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NoSQL DATABASE CLUSTER SECURITY GROUP
resource "aws_security_group" "nosql_db_cluster_sg" {
  name        = "nosql-db-cluster-sg"
  description = "Security group for NoSQL database cluster which allows just SSH and database traffic from game servers"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow internal communication between cluster nodes (self-referencing rule)
  ingress {
    description = "Allow nodes in this cluster to speak to each other"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow SSH access from a specific management IP address
  ingress {
    description = "SSH access for admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  # Allow FTP access from a specific IP address
  ingress {
    description = "FTP access from management host"
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.23/32"]
  }

  # Allow MongoDB access strictly from resources attached to the game server security group
  ingress {
    description     = "Database access from Game Servers only"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.game_server_compute_optimized_sg.id]
  }

  # Allow all outbound traffic from the database nodes
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}