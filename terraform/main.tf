provider "aws" {
  region = "us-east-1"
}

# ---------- VPC ----------
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "songapp-vpc"
  }
}

# ---------- Subnet ----------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "songapp-public-subnet"
  }
}

# ---------- Internet Gateway ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "songapp-igw" }
}

# ---------- Route Table ----------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "songapp-public-rt" }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------- Security Group ----------
resource "aws_security_group" "app_sg" {
  name   = "songapp-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "Allow all TCP inbound"
    from_port   = 0
    to_port     = 65535
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

# ---------- RDS MySQL ----------
resource "aws_db_instance" "song_rds" {
  identifier              = "songapp-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = "songsdb"
  username                = "admin"
  password                = "Cloud1234"
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.app_sg.id]
  skip_final_snapshot     = true

  tags = { Name = "songapp-rds" }
}

# ---------- EC2 Instance ----------
resource "aws_instance" "song_ec2" {
  ami                    = "ami-00c39f71452c08778" # Amazon Linux 2023
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  # No key pair needed — this EC2 runs automatically
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl start docker
              systemctl enable docker
              cd /home/ec2-user
              git clone https://github.com/abinash/song-app.git
              cd song-app
              docker-compose up -d --build
              EOF

  tags = {
    Name = "SongApp-Instance"
  }

  depends_on = [aws_db_instance.song_rds]
}

# ---------- Output ----------
output "ec2_public_ip" {
  description = "Public IP of the Song App EC2 instance"
  value       = aws_instance.song_ec2.public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.song_rds.address
}
