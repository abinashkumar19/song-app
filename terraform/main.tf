provider "aws" {
  region = "us-east-1"
}

# ---------------- VPC ----------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "songapp-vpc" }
}

# ---------------- Subnets ----------------
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "songapp-public-subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "songapp-public-subnet-2" }
}

# ---------------- Internet Gateway ----------------
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "songapp-igw" }
}

# ---------------- Route Table ----------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = { Name = "songapp-public-rt" }
}

# ---------------- Route Table Associations ----------------
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- Security Group ----------------
resource "aws_security_group" "main_sg" {
  name        = "songapp-sg"
  description = "Security group for Song App"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Flask Backend"
    from_port   = 5000
    to_port     = 5000
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

# ---------------- EC2 Instance ----------------
resource "aws_instance" "songapp_instance" {
  ami                         = "ami-00ca32bbc84273381" # Amazon Linux 2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.main_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git python3-pip
              systemctl start docker
              systemctl enable docker
              cd /home/ec2-user
              git clone https://github.com/abinashcloud/song-app.git
              cd song-app
              echo "DATABASE_URL=mysql+pymysql://${aws_db_instance.song_rds.username}:${aws_db_instance.song_rds.password}@${aws_db_instance.song_rds.endpoint}:3306/${aws_db_instance.song_rds.db_name}" > .env
              docker-compose up --build -d
              EOF

  tags = { Name = "songapp-instance" }
}

# ---------------- RDS Subnet Group ----------------
resource "aws_db_subnet_group" "song_subnet_group" {
  name       = "songapp-db-subnet-group"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  tags = { Name = "songapp-db-subnet-group" }
}

# ---------------- RDS Database ----------------
resource "aws_db_instance" "song_rds" {
  identifier              = "songapp-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0.39"
  instance_class          = "db.t3.micro"
  db_name                 = "songdb"
  username                = "admin"
  password                = "Admin12345!"
  publicly_accessible     = true
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.main_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.song_subnet_group.name
  tags = { Name = "songapp-db" }
}

# ---------------- Outputs ----------------
output "ec2_public_ip" {
  value = aws_instance.songapp_instance.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.song_rds.endpoint
}
