output "alb_dns_name" {                                  # 15 просто отдаем публичное днс имя по которому доступен наш лоадбалансер с приложением
  description = "The domain name of the load balancer"
  value = aws_lb.example.dns_name
}
