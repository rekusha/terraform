provider "aws" {
  region = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_state" {                # 1 создаем бакет S3 ресурсом (дял хранения конфигурайций
  bucket = "rekusha-terraform-up-and-running-state" # УНИКАЛЬНОЕ имя бакета

  lifecycle {
#    prevent_destroy = true                          # предотвращает случайное удаление
  }

  versioning {
    enabled = true                                  # включает версионирование файлов
  }

  server_side_encryption_configuration {            # включает шифрование содержимого указанным алгоритмом
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {           # 2 создаем таблицу в динамодб для реализации механизма блокировок файла состояния тераформа
  hash_key = "LockID"       # первичный ключь
  name     = "rekusha-terraform-up-and-running-state-locks" # имя таблицы
  billing_mode = "PAY_PER_REQUEST" # режим работы таблицы и тарифа

  attribute {
    name = "LockID"
    type = "S"
  }
}

#terraform {                                                # 3 конфигурация самой системы Terraform
#  backend "s3" {                                        # s3 это имя хранилища, которое будем использовать
#    key = "global/s3/terraform.tfstate"                 # Файловый путь внутри бакета S3, по которому Terraform будет записывать файл состояния
#    bucket = "rekusha-terraform-up-and-running-state"   # имя бакета где будет храниться
#    region = "eu-west-2"                                # Регион AWS, в котором находится бакет S3
#    dynamodb_table = "rekusha-terraform-up-and-running-state-locks" # Таблица DynamoDB, которая будет использоваться для блокирования
#    encrypt = true                                      # Если указать true, состояние Terraform будет шифроваться при сохранении в S3
# строки закоментированы так как эти данные передаются с помощью файла backend.hcl коммандой terraform init -backend-config="backend.hcl"
# внешний файл нужен из-за того, что у провайдера terraform не подгружаются значения переменных и поэтому для разных модулей придется вписывать значения каждый раз в ручную
# но используя внешний файл с параметрами можно передавать значения таким костылем
# !!! переменная key осталась не вынесенная потому как она у каждого модуля должна быть своя и уникальная чтоб не перезаписывать данные разных модулей одним ключем !!!
#  }
#}

#output "s3_bucket_arn" {
#  value = aws_s3_bucket.terraform_state.arn
#  description = "The ARN of the S3 bucket"
#}
#
#output "dynamodb_table_name" {
#  value = aws_dynamodb_table.terraform_locks.name
#  description = "The name of the DynamoDB table"
#}

