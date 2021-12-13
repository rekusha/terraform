# backend.hcl
bucket = "rekusha-terraform-up-and-running-state"   # имя бакета где будет храниться
region = "eu-west-2"                                # Регион AWS, в котором находится бакет S3
dynamodb_table = "rekusha-terraform-up-and-running-state-locks" # Таблица DynamoDB, которая будет использоваться для блокирования
encrypt = true