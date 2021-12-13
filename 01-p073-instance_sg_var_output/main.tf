provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "example" {                       # 1 создается ресурс который развернет инстанс (вм)
  ami = "ami-0fdf70ed5c34c5f52"                           # 1.1 указывается ид образа из которого будет создан инстанс
  instance_type = "t2.micro"                              # 1.2 указывается на каком типе инстанса будет развернут ресурс
  tags = {                                                # 1.3 создается тэг/и который будут присвоему инстансу
    Name = "terraform-example-01"
  }
  # 2 ниже добавляется блок юзер дата который будет выполнен после создания инстанса (типа автозагрузки)
  user_data = <<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF
  # ${var.server_port} это строковая интерполяция - терраформ преобразует любую корректную ссылку в строку
  vpc_security_group_ids = [aws_security_group.instance.id] # 5 в параметрах инстанса указывается принадлежность к секьюрити_группе чтоб применить правила эой группы к инстансу
  # по сути шаг 5 это создание неявной зависимости
  # зависимости можно вывести коммандой terraform graph и посмотреть зависимости в графичеком представленни на сайте http://dreampuf.github.io/GraphvizOnline/
}

resource "aws_security_group" "instance" {                  # 3 создается ресурс секьюрити_груп
  name = "terraform-example-instance"
  ingress {                                                 # 4 созхдается правило для входящего трафика с порта 8080 на порт 8080 из любого источника 0.0.0.0/0
    from_port = var.server_port  # var.___ это ссылка на ВХОДНУЮ переменную которая определена в сценарии
    protocol  = "tcp"
    to_port   = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {                                    # 6 создается ВХОДНАЯ переменная у которой настоятельно рекомендуется наличие полей description и type
  description = "The port the server will use for HTTP requests"  # описание переменной
  type = number                                                   # тип переменной string, number, bool, list, map, set, object, tuple и any
  default = 8081                                                  # значение переменной по умолчанию. используется только в случае если переменная не была передада предварительно с помощью -var -var-file или наличием переменной среды TF_VAR_имя_перменной
  # если дефолтное значение не указать и не передать переменную явно, то при запуске терраформ попросит ввести значение переменной ручками
}

output "test_output_variable" {                             # 7 создается ВЫХОДНАЯ переменная отличается от входной тем что данные в нее попадают из облака, а не задаются нами
  value = aws_instance.example.public_ip        # ссылка на данные что будут присвоены переменной
  description = "The public IP address of the " # описание переменной (настоятльно рекомендуется указывать)
  sensitive = false                             # ключ который может скрывать чувствительные данные например пароли
}                                               # коммандо terraform output <variable_name> кожно вывести значение переменной

