
variable "aws_region" {
  description = "AWS region P4 benchmark infrastructure will be deployed into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block to use for AWS VPC.  Subnets will be automatically calculated from this block."
  type        = string
  default     = "10.0.0.0/16"
}


variable "ami" {
  description = "AMI ID to use for Helix Core commit server"
  type        = map(string)
  default = {
    "ap-northeast-1" = "ami-01e2129786264c400"
    "ap-northeast-2" = "ami-0b2fa7ea904b161a2"
    "ap-northeast-3" = "ami-03f0db6da7bf1306b"
    "ap-south-1"     = "ami-0ae3983379cc494e8"
    "ap-southeast-1" = "ami-05e206dcf928c9078"
    "ap-southeast-2" = "ami-08f949b2fcb6b3d31"
    "ca-central-1"   = "ami-040bde0518bd7a6ba"
    "eu-central-1"   = "ami-09c91fa399c2a81a5"
    "eu-north-1"     = "ami-06a373eb52abbdb68"
    "eu-west-1"      = "ami-03fb8569c4ace9810"
    "eu-west-2"      = "ami-0d2077cad9d054467"
    "eu-west-3"      = "ami-03fd0715c41b21f32"
    "sa-east-1"      = "ami-090e455d221336b23"
    "us-east-1"      = "ami-0455b6b2905b565f0"
    "us-east-2"      = "ami-060651d43696ebc01"
    "us-west-1"      = "ami-05ed8d8d0c5c5e7b9"
    "us-west-2"      = "ami-0b95e65da22d3f62b"
  }
}

# not implemented yet
# variable "helix_core_p4d_configurables" {
#   description = "Array of p4d configurables to apply at deploy time"
#   type        = list(string)
#   default = [
#     "p4 configure set net.parallel.max=100",
#     "p4 configure set net.parallel.threads=10"
#   ]
# }

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = null
}

variable "owner" {
  description = "Who is the owner of this infrastructure?  This value will be applied as a tag to all resources."
  type        = string
}

variable "depot_volume_size" {
  description = "Volume size for Depot volume"
  type        = number
  default     = 500
}

variable "depot_volume_type" {
  description = "Volume type for Depot volume"
  type        = string
  default     = "gp3"
}

variable "depot_volume_throughput" {
  description = "Volume throughput for Depot volume (only valid for volume type GP3)"
  type        = number
  default     = null
}

variable "log_volume_throughput" {
  description = "Volume throughput for Log volume (only valid for volume type GP3)"
  type        = number
  default     = null
}

variable "metadata_volume_throughput" {
  description = "Volume throughput for Metadata volume (only valid for volume type GP3)"
  type        = number
  default     = null
}



variable "volumes_encrypted" {
  description = "Wether to encrypt the volumes with KMS.  If this is set to true kms_key_id must also me set."
  type        = bool
  default     = false
}

variable "volumes_kms_key_id" {
  description = "KMS key ID to use to encrypt the volumes.  This must be set if `volumes_encrypted` is true"
  type        = string
  default     = null
}

variable "depot_volume_iops" {
  description = "How many IOPS to create the Depot volume with."
  type        = number
  default     = null
}

variable "log_volume_size" {
  description = "Volume size for Log volume"
  type        = number
  default     = 50
}

variable "log_volume_type" {
  description = "Volume type for Log volume"
  type        = string
  default     = "gp3"
}

variable "log_volume_iops" {
  description = "How many IOPS to create the Log volume with."
  type        = number
  default     = null
}

variable "metadata_volume_size" {
  description = "Volume size for Metadata volume"
  type        = number
  default     = 50
}

variable "metadata_volume_type" {
  description = "Volume type for Metadata volume"
  type        = string
  default     = "gp3"
}

variable "metadata_volume_iops" {
  description = "How many IOPS to create the Metadata volume with."
  type        = number
  default     = null
}

variable "environment" {
  description = "What environment is this for?  This value will be applied to all resources as a tag"
  type        = string
  default     = "test"
}



variable "key_name" {
  description = "Key name of the Key Pair to use for all instances."
  type        = string
}

variable "monitoring" {
  description = "If true, the Helix Core EC2 instance will have detailed monitoring enabled."
  type        = bool
  default     = true
}

variable "helix_coreprivate_ip" {
  description = "Private IP address to associate with the Helix Core instance in a VPC.  Leave null to allow DHCP to assign IP address."
  type        = string
  default     = null
}

variable "helix_core_commit_instance_type" {
  description = "The type of instance to start."
  type        = string
  default     = "c5.xlarge"
}



variable "ingress_cidrs_1666" {
  description = "CIDR blocks to whitelist for Helix Core access"
  type        = string
  default     = ""
}

variable "ingress_cidrs_22" {
  description = "CIDR blocks to whitelist for Helix Core SSH access"
  type        = string
  default     = ""
}

variable "ingress_cidrs_locust" {
  description = "CIDR blocks to whitelist for Locust SSH access"
  type        = string
  default     = ""
}

variable "ingress_cidrs_3000" {
  description = "CIDR blocks to whitelist for Grafana access"
  type        = list(string)
  default     = [""]
}






variable "client_vm_count" {
  description = "Number of EC2 instances to create for Locust clients"
  type        = number
  default     = 1
}

variable "client_instance_type" {
  description = "The type of instance to for Locust clients"
  type        = string
  default     = "t3.small"
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



variable "client_root_volume_size" {
  description = "The size of the root volume for the Locust clients"
  type        = number
  default     = 100
}

variable "client_root_volume_type" {
  description = "The root volume type for Locust clients"
  type        = string
  default     = "gp3"
}



variable "driver_instance_type" {
  description = "The type of instance to for driver"
  type        = string
  default     = "t3.small"
}

variable "driver_root_volume_size" {
  description = "The size of the root volume for the driver"
  type        = number
  default     = 100
}

variable "driver_root_volume_type" {
  description = "The root volume type for driver"
  type        = string
  default     = "gp2"
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



variable "helix_core_commit_username" {
  description = "Username to use for administoring Helix Core"
  type        = string
  default     = "perforce"
}

variable "helix_core_commit_benchmark_username" {
  description = "Username to use when running benchmark against Helix Core"
  type        = string
  default     = "bruno"
}

variable "p4benchmark_os_user" {
  description = "What user Ansible should use for authenticating to all hosts"
  type        = string
  default     = "perforce"
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

variable "number_locust_workers" {
  description = "Number of Locust worker threads"
  type        = number
  default     = 2
}

variable "s3_checkpoint_bucket" {
  description = "Name of the S3 bucket that contains checkpoints"
  type        = string
  default     = ""
}

variable "checkpoint_filename" {
  description = "Name of the checkpoint file in S3"
  type        = string
  default     = ""
}

variable "license_filename" {
  description = "Name of the license file in S3"
  type        = string
  default     = "license"
}

variable "archive_filename" {
  description = "Name of the archive file in S3 (must be .tgz file)"
  type        = string
  default     = ""
}

variable "existing_vpc" {
  description = "Whether or not to use an existing VPC or create one"
  type        = bool
  default     = false
}

variable "existing_helix_core" {
  description = "Whether or not to use an existing Helix Core or create one"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID to use for EC2 deployments"
  type        = string
  default     = ""
}

variable "existing_public_subnet" {
  description = "Existing public subnet ID to use for EC2 deployments"
  type        = string
  default     = ""
}

variable "existing_az" {
  description = "Existing Availability Zone to create Helix Core volumes in"
  type        = string
  default     = ""
}

variable "existing_sg_ids" {
  description = "Existing security group ID to use for network connectivity between locust client machines and Helix Core"
  type        = list(string)
  default     = []
}

variable "existing_helix_core_ip" {
  description = "Existing helix core IP for locust clients to use for P4PORT"
  type        = string
  default     = ""
}

variable "existing_helix_core_public_ip" {
  description = "Existing helix core public IP for terraform to connect via remote-exec for configuration"
  type        = string
  default     = ""
}

variable "existing_helix_core_port" {
  description = "Existing helix core port for locust clients to use for P4PORT"
  type        = string
  default     = "1666"
}

variable "existing_helix_core_username" {
  description = "Existing helix core username for locust clients to use for P4USER"
  type        = string
  default     = ""
}

variable "existing_helix_core_password" {
  description = "Existing helix core password for locust clients to use for p4 login"
  type        = string
  default     = ""
}

variable "install_p4prometheus" {
  description = "Wether or not to install p4prometheus on the driver EC2 instance"
  type        = bool
  default     = true
}
