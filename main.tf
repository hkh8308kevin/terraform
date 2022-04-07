provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_launch_configuration" "launch_config" { 
  name = "terraform-web-launch-config"
  image_id = "ami-0dd97ebb907cf9366" 
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello,World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  lifecycle {
   create_before_destroy = true
 }
} 

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
  from_port = var.server_port
  to_port   = var.server_port
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    from_port = 80
    to_port =80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "WEB-ASG" {
  name = "terraform-web-asg"
  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.tg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  tag {
   key  = "Name"
   value = "terraform-web-asg-server"
   propagate_at_launch = true
  } 
}

resource "aws_lb" "example" {
  name = "terraform-lb-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
   type = "fixed-response"
   
   fixed_response {
    content_type = "text/plain"
    message_body = "404: page not found"
    status_code = 404
   }
  }
}

resource "aws_lb_target_group" "tg" {
  name = "terraform-tg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path =  "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
   path_pattern {
     values = ["*"]
   }
  }
  
  action {
   type = "forward"
   target_group_arn = aws_lb_target_group.tg.arn
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
data "aws_vpc" "default" {
  default = true
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The domain name of the load blancer"
}

