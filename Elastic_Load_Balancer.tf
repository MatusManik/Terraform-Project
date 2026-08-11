# APPLICATION LOAD BALANCER (ALB)
# Public-facing load balancer distributing web traffic across two public subnets
resource "aws_lb" "web_application_load_balancer" {
    name               = "web-application-load-balancer"
    load_balancer_type = "application"
    internal           = false

    subnets = [
        aws_subnet.public_subnet_one.id,
        aws_subnet.public_subnet_two.id
    ]

    security_groups = [
        aws_security_group.alb_security_group.id
    ]

    tags = {
        Name = "Application-Load-Balancer"
    }
}

# TARGET GROUP
# Target group routing HTTP traffic to backend EC2 instances on port 80
resource "aws_lb_target_group" "web_target_group" {
    name        = "web-target-group"
    protocol    = "HTTP"
    port        = 80
    vpc_id      = aws_vpc.main_vpc.id
    target_type = "instance"

    # Health check configuration to verify instance availability
    health_check {
        enabled             = true
        protocol            = "HTTP"
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
    }
}

# ALB LISTENER
# Listens on HTTP port 80 and forwards incoming traffic to the web target group
resource "aws_lb_listener" "http_listener" {
    load_balancer_arn = aws_lb.web_application_load_balancer.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.web_target_group.arn
    }
}

# ALB Listener Rule used to associate a target group to a listener and also specify conditions for this association
resource "aws_lb_listener_rule" "http_listener_rule" {
    listener_arn = aws_lb_listener.http_listener.arn
    priority = 100

    action {
      type = "forward"
      target_group_arn = aws_lb.web_application_load_balancer.arn
    }

    condition {
      source_ip {
        values = ["193.87.0.0/16", "203.0.113.5/32"]
      }
    }
  
}