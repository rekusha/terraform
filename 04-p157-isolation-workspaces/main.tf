provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket = "rekushas-state"
    key = "workspaces-example/terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "rekushas-04-p157-locks"
    encrypt = true
  }
}

resource "aws_instance" "example" {
  ami = "ami-0fdf70ed5c34c5f52"
  instance_type = "t2.micro"
  tags = {
    Name = "04-p157-${terraform.workspace}"
  }
}


# terraform workspace show - выведет информацию о текущей рабочей области
# terraform workspace list - выведет список рабочех областей
# terraform workspace new example1 - создает новый воркспейс
# terraform workspace select <worckspace> - перемещение в указанную рабочую область

