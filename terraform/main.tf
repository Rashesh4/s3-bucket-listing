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

resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2_s3_access_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_instance" "demo_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.demo_key_pair.key_name

  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              set -e  # Exit immediately if a command exits with a non-zero status

              echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

              sudo apt-get update -y 
              sudo apt-get install -y python3-pip nginx

              git clone https://github.com/Rashesh4/s3-bucket-listing.git 
              cd s3-bucket-listing/app
              pip3 install -r requirements.txt
              echo "S3_BUCKET_NAME=${var.bucket_name}" >> .env
              echo "AWS_DEFAULT_REGION=${var.aws_region}" >> .env

              nohup python3 app.py > app.log 2>&1 &

              sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

              cat <<EOT > /etc/nginx/sites-available/default
              server {
                  listen 443 ssl;
                  server_name localhost;

                  ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
                  ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

                  location / {
                      proxy_pass http://localhost:5000;
                      proxy_set_header Host \$host;
                      proxy_set_header X-Real-IP \$remote_addr;
                  }
              }
              EOT

              # Restart NGINX
              sudo systemctl restart nginx

              echo "User data script execution completed"
              EOF

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

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
    from_port   = 443
    to_port     = 443
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
