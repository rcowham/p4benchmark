variable "environment" {
  description = "What environment is this for?  This value will be applied to all resources as a tag"
  type        = string
  default     = "test"
}

variable "owner" {
  description = "Who is the owner of this infrastructure?  This value will be applied as a tag to all resources."
  type        = string
}

variable "helix_core_admin_user" {
  description = "Admin user name for for the Virtual Machine with Helix-Core."
  type        = string
}

variable "helix_core_admin_password" {
  description = "Admin user password for for the Virtual Machine with Helix-Core."
  type        = string
}

variable "azure_region" {
  description = "Azure region P4 benchmark infrastructure will be deployed into."
  type        = string
  default     = "eastus"
}

variable "p4benchmark_os_user" {
  description = "What user Ansible should use for authenticating to all hosts"
  type        = string
  default     = "perforce"
}

variable "license_filename" {
  description = "Name of the license file in S3"
  type        = string
  default     = ""
}

variable "s3_checkpoint_bucket" {
  description = "Name of the S3 bucket that contains checkpoints"
  type        = string
  default     = ""
}
