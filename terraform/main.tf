# ==============================================
# Main Terraform Configuration
# ==============================================
# This file serves as the entry point.
# All resources are organized in separate files.
# ==============================================

# Local variables for computed values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
