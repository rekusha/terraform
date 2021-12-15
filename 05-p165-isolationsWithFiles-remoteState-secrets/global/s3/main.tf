provider "aws" {
  region = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "05-rekushas-state"
  lifecycle {
    prevent_destroy = true
  }
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  hash_key = "LockID"
  name     = "rekushas-05-p165-locks"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket = "05-rekushas-state"
    key = "global/s3/terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "rekushas-05-p165-locks"
    encrypt = true
  }
}