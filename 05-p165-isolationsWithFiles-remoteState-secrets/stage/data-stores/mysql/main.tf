provider "aws" {
region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket = "05-rekushas-state"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "rekushas-05-p165-locks"
    encrypt = true
  }
}

resource "aws_db_instance" "example" {
identifier_prefix = "terraform-up-and-running"
engine = "mysql"
allocated_storage = 10
instance_class = "db.t2.micro"
name = "example_database"
username = "admin"
# разобраться с менеджерами паролей!!!
password = "password" #data.aws_secretsmanager_secret_version.db_password.secret_string
  skip_final_snapshot = true
}

data "aws_secretsmanager_secret_version" "_05_p165" {
  secret_id = "terraformdbpassword"
}

