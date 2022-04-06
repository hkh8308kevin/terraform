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

resource "aws_autoscaling_group" "WEB-ASG" {
  name = "terraform-web-asg"
  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  min_size = 2
  max_size = 3

  tag {
   key  = "Name"
   value = "terraform-web-asg-server"
   propagate_at_launch = true
  } 
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
data "aws_vpc" "default" {
  default = true
}
