provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_object" "dir1" {
  bucket = aws_s3_bucket.demo_bucket.id
  key    = "dir1/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "dir2" {
  bucket = aws_s3_bucket.demo_bucket.id
  key    = "dir2/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "file1_in_dir2" {
  bucket = aws_s3_bucket.demo_bucket.id
  key    = "dir2/file1.txt"
  content = "This is file1 in dir2"
  content_type = "text/plain"
}

resource "aws_s3_object" "file2_in_dir2" {
  bucket = aws_s3_bucket.demo_bucket.id
  key    = "dir2/file2.txt"
  content = "This is file2 in dir2"
  content_type = "text/plain"
}

resource "aws_key_pair" "demo_key_pair" {
  key_name   = "demo-key-pair"
  public_key = file("C:/Users/rashe/.ssh/id_rsa.pub")
}

resource "aws_instance" "demo_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name = aws_key_pair.demo_key_pair.key_name

  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
            echo "Starting user data script execution"
            sudo apt-get update -y
            echo "apt-get update completed"
            sudo apt-get install -y python3-pip
            echo "python3-pip installed"
            git clone https://github.com/Rashesh4/s3-bucket-listing.git
            echo "Repository cloned"
            cd s3-bucket-listing/app
            pip3 install -r requirements.txt
            echo "Dependencies installed"
            echo "S3_BUCKET_NAME=${var.bucket_name}" >> .env
            echo "AWS_DEFAULT_REGION=${var.aws_region}" >> .env
            echo "Environment variables set"
            nohup python3 app.py > app.log 2>&1 &
            echo "Application started"
            echo "User data script execution completed"
            EOF

  tags = {
    Name = "demo-instance"
  }
}

resource "aws_security_group" "demo_sg" {
  name        = "demo-sg"
  description = "Allow inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}
