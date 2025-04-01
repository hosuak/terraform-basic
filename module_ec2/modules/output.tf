output "public_ip" {
  value = aws_instance.demo_instance.public_ip
}

output "private_key" {
  value = module.demo_key_pair.private_key_pem
}