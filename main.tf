provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "java_app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "java_app" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.java_app_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-1.8.0-openjdk
              cd /home/ec2-user
              echo 'public class HelloWorld {' > HelloWorld.java
              echo '  public static void main(String[] args) {' >> HelloWorld.java
              echo '    System.out.println("Hello, World!");' >> HelloWorld.java
              echo '  }' >> HelloWorld.java
              echo '}' >> HelloWorld.java
              javac HelloWorld.java
              java HelloWorld > /var/log/helloworld.log 2>&1 &
              EOF

  tags = {
    Name = "JavaAppInstance"
  }
}

output "instance_public_ip" {
  value = aws_instance.java_app.public_ip
}
