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

variable "helix_core_commit_benchmark_username" {
  description = "Username to use when running benchmark against Helix Core"
  type        = string
  default     = "bruno"
}

variable "p4benchmark_github_project_owner" {
  description = "GitHub owner of the p4benchmark project"
  type        = string
  default     = "rcowham"
}

variable "p4benchmark_github_project" {
  description = "GitHub project name"
  type        = string
  default     = "p4benchmark"
}

variable "p4benchmark_github_branch" {
  description = "GitHub project branch name"
  type        = string
  default     = "main"
}

variable "p4benchmark_dir" {
  description = "The directory where p4benchmark code will be checked out to"
  type        = string
  default     = "/p4benchmark"
}

variable "locust_workspace_dir" {
  description = "The directory the p4 locust clients will use"
  type        = string
  default     = "/p4/work"
}

variable "client_root_volume_size" {
  description = "The size of the root volume for the Locust clients"
  type        = number
  default     = 100
}

variable "client_root_volume_type" {
  description = "The root volume type for Locust clients"
  type        = string
  default     = "Standard_LRS"
}

variable "client_vm_count" {
  description = "Number of Azure VM instances to create for Locust clients"
  type        = number
  default     = 1
}

variable "client_instance_type" {
  description = "The type of instance to for Locust clients"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "helix_core_commit_username" {
  description = "Username to use for administoring Helix Core"
  type        = string
  default     = "perforce"
}

variable "number_locust_workers" {
  description = "Number of Locust worker threads"
  type        = number
  default     = 2
}

variable "install_p4prometheus" {
  description = "Wether or not to install p4prometheus on the driver VM instance"
  type        = bool
  default     = true
}

variable "locust_repo_path" {
  description = "The depot path locust clients will create their workspaces from"
  type        = string
  default     = "//depot/*"
}

variable "locust_repo_dir_num" {
  description = "Number of entires to select from p4 dirs output.  p4 dirs output will be limited by value of locust_repo_path"
  type        = string
  default     = "5"
}

variable "locust_repeat" {
  description = "How many times the locust client will repeat the loop"
  type        = string
  default     = "5"
}

variable "driver_instance_type" {
  description = "The type of instance to for driver"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "driver_root_volume_size" {
  description = "The size of the root volume for the driver"
  type        = number
  default     = 100
}

variable "driver_root_volume_type" {
  description = "The root volume type for driver"
  type        = string
  default     = "Standard_LRS"
}

variable "createfile_configs" {
  description = "createfile_configs is an array of maps.  Each object will be passed to createfiles.py.  Use an empty array if you want to skip running createfiles.py from terraform"
  type        = list(map(string))

  # https://github.com/rcowham/p4benchmark#creating-repository-files
  default = [
    {
      createfile_levels    = "25 25" # Directories to create at each level, e.g. -l 5 10
      createfile_size      = "10000" # Average size of files
      createfile_number    = "10000" # Number of files to create
      createfile_directory = "ws1"   # Directory under /tmp/ to create and use for the p4 workspace
    }
  ]
}