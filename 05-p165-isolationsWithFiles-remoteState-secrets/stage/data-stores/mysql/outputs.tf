output "db_pass" {
  value = data.aws_secretsmanager_secret_version._05_p165
  sensitive = true
}

output "address" {
value = aws_db_instance.example.address
description = "Connect to the database at this endpoint"
}

output "port" {
value = aws_db_instance.example.port
description = "The port the database is listening on"
}