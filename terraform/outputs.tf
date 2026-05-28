# ==============================================
# Terraform Outputs
# ==============================================
# Values displayed after terraform apply
# ==============================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "app_server_public_ip" {
  description = "Public IP of the application server"
  value       = aws_instance.app_server.public_ip
}

output "app_server_public_dns" {
  description = "Public DNS of the application server"
  value       = aws_instance.app_server.public_dns
}

output "jenkins_server_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${aws_instance.jenkins_server.public_ip}:8080"
}

output "monitoring_server_public_ip" {
  description = "Public IP of the monitoring server"
  value       = aws_instance.monitoring_server.public_ip
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${aws_instance.monitoring_server.public_ip}:3001"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${aws_instance.monitoring_server.public_ip}:9090"
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "ssh_commands" {
  description = "SSH commands to connect to servers"
  value = {
    app_server        = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.app_server.public_ip}"
    jenkins_server    = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.jenkins_server.public_ip}"
    monitoring_server = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.monitoring_server.public_ip}"
  }
}
