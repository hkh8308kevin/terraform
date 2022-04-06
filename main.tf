provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" { 
  ami = "ami-0dd97ebb907cf9366" 
  instance_type = "t2.micro"

  tags = {
   Name = "terraform-example"
  }
} 
