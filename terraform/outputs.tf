output "instance_public_ip" {
  value = aws_instance.demo_instance.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.demo_bucket.id
}