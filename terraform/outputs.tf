# ==============================================
# Terraform Outputs - Single Server
# ==============================================
# Values displayed after terraform apply
# ==============================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "single_server_public_ip" {
  description = "Public IP of the single all-in-one server"
  value       = aws_eip.single_server.public_ip
}

output "single_server_ssh" {
  description = "SSH command for the single server"
  value       = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_eip.single_server.public_ip}"
}

output "single_server_app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.single_server.public_ip}"
}

output "single_server_grafana_url" {
  description = "Grafana URL"
  value       = "http://${aws_eip.single_server.public_ip}:3001"
}

output "single_server_prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${aws_eip.single_server.public_ip}:9090"
}
