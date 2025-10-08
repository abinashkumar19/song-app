provider "aws" {
  region = "us-east-1"
}

# -------------------------
# VPC + Subnets
# -------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "songapp-vpc" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = { Name = "songapp-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "songapp-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name   = "songapp-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "songapp-sg" }
}

# -------------------------
# RDS (MySQL)
# -------------------------
resource "aws_db_subnet_group" "song_subnet_group" {
  name       = "songapp-db-subnet-group"
  subnet_ids = [aws_subnet.public_subnet.id]
}

resource "aws_db_instance" "song_rds" {
  identifier              = "songapp-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "admin12345"
  db_name                 = "songdb"
  skip_final_snapshot     = true
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.main_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.song_subnet_group.name
}

# -------------------------
# EC2 Instance (App Server)
# -------------------------
resource "aws_instance" "songapp_ec2" {
  ami                    = "ami-00ca32bbc84273381" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl enable docker
              systemctl start docker
              EOF
  tags = { Name = "songapp-ec2" }
}
