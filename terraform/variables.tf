variable "aws_region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "bucket_name" {
  description = "testbucketrashesh"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0c55b159cbfafe1f0"  # Ubuntu 20.04 LTS in us-west-2
}

variable "key_name" {
  description = "ec2-KP"
}