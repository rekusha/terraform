terraform {
  backend "s3" {
    bucket = "05-rekushas-state"
    key = "stage/services/webservercluster/terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "rekushas-05-p165-locks"
    encrypt = true
  }
}

resource "aws_launch_configuration" "example" {    # 1  конфигурацию запуска, которая определяет, как нужно настроить каждый сервер EC2 в группе
  image_id      = "ami-0fdf70ed5c34c5f52"                  # указываем на каком образе будут развернуты машины кластера
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]       # указываем к какой секьюрити группе будут соотнесены машины кластера
  user_data = <<-EOF
#!/bin/bash
myip='curl http://196.254.169.254/latest/meta-data/local-ipv4'
echo "Hello, World ${data.aws_vpc.default.id}<br> Terraform <br>" > index.html
echo "${data.terraform_remote_state.db.outputs.address} <br>" >> index.html
echo "${data.terraform_remote_state.db.outputs.port} <br>" >> index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF
  lifecycle {
    create_before_destroy = true                    # 3 поменяет порядок замены ресурсов, сначало создаст новый и только потом удалит старый
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = var.server_port
    protocol  = "tcp"
    to_port   = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "example" {          # 2 именно здесь создается кластер
  launch_configuration = aws_launch_configuration.example.name # параметр указывает конфигурацию(шаблон) инстансов запускаемых для кластера

  vpc_zone_identifier = data.aws_subnet_ids.default.ids # 6  извлечь идентификаторы подсетей из источника aws_subnet_ids
  # и воспользоваться аргументом с довольно странным названием vpc_zone_identifier, чтобы кластер использовал эти подсети

  target_group_arns = [aws_lb_target_group.asg.arn]   # 12 указывает на использование целевой группы
  health_check_type = "ELB"                           # 13 устанавливает значение типа проверки серверов со стандартной "EC2" на другую
  # стандартный тип проверки "EC2" проверяет только то жив ли инстанс по версии гипервизора, ЕЛБ же утверждает что инстанс умер даже если не хватает памяти или перестают обслуживать запросы

  min_size = 2        # минимальное количество копий инстанса
  max_size = 10       # максимальное кол-во копий в кластере
  tag {
    key                 = "Name"
    propagate_at_launch = true  #
    value               = "terraform-asg-example"
  }
}
 data "aws_vpc" "default" {                             # 4 запросить информацию о вашем облаке VPC по умолчанию
   default = true  # указывается тру только если получаем информацию о vpc по умолчанию
 }

data "aws_subnet_ids" "default" {                       # 5 найти подсети внутри этого облака VPC из того что выше сделали
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "example" {                           # 7 создаем балансировщик ELB тип ALB для приложений работающих с http/s
  name = "terraform-ASG-example"
  load_balancer_type = "application" # есть три типа балансировщикой ApplicationLB(http/s), NetworkLB(tcp/udp) и устаревший ClassicLB(all in one)
  subnets = data.aws_subnet_ids.default.ids # параметр subnets настраивает балансировщик нагрузки для использования всех подсетей в облаке VPC по умолчанию
  security_groups = [aws_security_group.alb.id]         # 10 указывает какую использовать сукьюрити группу
}

resource "aws_lb_listener" "http" {                     # 8 это прослушиватель для лоад балансира (для работы нужжна секьюрити группа с нужными окрытыми портами на вход и все на выход)
  load_balancer_arn = aws_lb.example.arn # указывается к какому балансиру относится
  port = 80                              # какой порт слушает
  protocol = "HTTP"                      # какой протокол ожитает на входе
  default_action {                       # возвращает страницу с кодом 404 в случае, если запрос не соответствует ни одному из правил прослушивания.
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {                   # 9 секьюрити группа для апликэйшн лоад балансира
  name = "terraform-example-alb"
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {                  # 11 создаем целевую группу которая будер проверять работоспособность наших серверов отправляя им хттп запросы
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200" # если сервер отвечает кодом 200 то он считается работоспособным
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {                  # 14 создает правило прослушивания которое форвардит (type = "forward") запросы по маске path_pattern к целевой группе target_group_arn
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "05-rekushas-state"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-west-2"
  }
}
