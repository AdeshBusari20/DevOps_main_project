# ==============================================
# AMI Data Source
# ==============================================
# Fetches the latest Ubuntu 22.04 LTS AMI from
# Canonical. Used by ec2-single.tf.
# ==============================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
