provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "example" {
  ami = "ami-0fdf70ed5c34c5f52"
  instance_type = "t2.micro"
  tags = {
    Name = "terraform-example-01"
  }
}
