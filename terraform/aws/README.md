<!-- BEGIN_TF_DOCS -->



## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | ID of AMI to use for the instance | `map(string)` | <pre>{<br>  "ap-northeast-1": "ami-01e2129786264c400",<br>  "ap-northeast-2": "ami-0b2fa7ea904b161a2",<br>  "ap-northeast-3": "ami-03f0db6da7bf1306b",<br>  "ap-south-1": "ami-0ae3983379cc494e8",<br>  "ap-southeast-1": "ami-05e206dcf928c9078",<br>  "ap-southeast-2": "ami-08f949b2fcb6b3d31",<br>  "ca-central-1": "ami-040bde0518bd7a6ba",<br>  "eu-central-1": "ami-09c91fa399c2a81a5",<br>  "eu-north-1": "ami-06a373eb52abbdb68",<br>  "eu-west-1": "ami-03fb8569c4ace9810",<br>  "eu-west-2": "ami-0d2077cad9d054467",<br>  "eu-west-3": "ami-03fd0715c41b21f32",<br>  "sa-east-1": "ami-090e455d221336b23",<br>  "us-east-1": "ami-0455b6b2905b565f0",<br>  "us-east-2": "ami-060651d43696ebc01",<br>  "us-west-1": "ami-05ed8d8d0c5c5e7b9",<br>  "us-west-2": "ami-0b95e65da22d3f62b"<br>}</pre> | no |
| <a name="input_archive_filename"></a> [archive\_filename](#input\_archive\_filename) | Name of the archive file in S3 (must be .tgz file) | `string` | `""` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Whether to associate a public IP address with an instance in a VPC | `bool` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region P4 benchmark infrastructure will be deployed into. | `string` | `"us-east-1"` | no |
| <a name="input_checkpoint_filename"></a> [checkpoint\_filename](#input\_checkpoint\_filename) | Name of the checkpoint file in S3 | `string` | `""` | no |
| <a name="input_client_instance_type"></a> [client\_instance\_type](#input\_client\_instance\_type) | The type of instance to for Locust clients | `string` | `"t3.small"` | no |
| <a name="input_client_root_volume_size"></a> [client\_root\_volume\_size](#input\_client\_root\_volume\_size) | The size of the root volume for the Locust clients | `number` | `100` | no |
| <a name="input_client_root_volume_type"></a> [client\_root\_volume\_type](#input\_client\_root\_volume\_type) | The root volume type for Locust clients | `string` | `"gp3"` | no |
| <a name="input_client_vm_count"></a> [client\_vm\_count](#input\_client\_vm\_count) | Number of EC2 instances to create for Locust clients | `number` | `1` | no |
| <a name="input_createfile_directory"></a> [createfile\_directory](#input\_createfile\_directory) | Create Files - Directory where to start | `string` | `"/tmp/ws"` | no |
| <a name="input_createfile_levels"></a> [createfile\_levels](#input\_createfile\_levels) | Create Files - Directories to create at each level, e.g. -l 5 10 | `string` | `"10 10"` | no |
| <a name="input_createfile_number"></a> [createfile\_number](#input\_createfile\_number) | Create Files - Number of files to create | `string` | `"100"` | no |
| <a name="input_createfile_size"></a> [createfile\_size](#input\_createfile\_size) | Create Files - Average size of files | `string` | `"20000"` | no |
| <a name="input_depot_volume_iops"></a> [depot\_volume\_iops](#input\_depot\_volume\_iops) | How many IOPS to create the Depot volume with. | `number` | `null` | no |
| <a name="input_depot_volume_size"></a> [depot\_volume\_size](#input\_depot\_volume\_size) | Volume size for Depot volume | `number` | `500` | no |
| <a name="input_depot_volume_throughput"></a> [depot\_volume\_throughput](#input\_depot\_volume\_throughput) | Volume throughput for Depot volume (only valid for volume type GP3) | `number` | `null` | no |
| <a name="input_depot_volume_type"></a> [depot\_volume\_type](#input\_depot\_volume\_type) | Volume type for Depot volume | `string` | `"gp3"` | no |
| <a name="input_driver_instance_type"></a> [driver\_instance\_type](#input\_driver\_instance\_type) | The type of instance to for driver | `string` | `"t3.small"` | no |
| <a name="input_driver_root_volume_size"></a> [driver\_root\_volume\_size](#input\_driver\_root\_volume\_size) | The size of the root volume for the driver | `number` | `100` | no |
| <a name="input_driver_root_volume_type"></a> [driver\_root\_volume\_type](#input\_driver\_root\_volume\_type) | The root volume type for driver | `string` | `"gp2"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Availability Zone EBS volumes we be created in. | `string` | `"dev"` | no |
| <a name="input_existing_az"></a> [existing\_az](#input\_existing\_az) | Existing Availability Zone to create Helix Core volumes in | `string` | `""` | no |
| <a name="input_existing_helix_core"></a> [existing\_helix\_core](#input\_existing\_helix\_core) | Whether or not to use an existing Helix Core or create one | `bool` | `false` | no |
| <a name="input_existing_helix_core_ip"></a> [existing\_helix\_core\_ip](#input\_existing\_helix\_core\_ip) | Existing helix core IP for locust clients to use for P4PORT | `string` | `""` | no |
| <a name="input_existing_helix_core_password"></a> [existing\_helix\_core\_password](#input\_existing\_helix\_core\_password) | Existing helix core password for locust clients to use for p4 login | `string` | `""` | no |
| <a name="input_existing_helix_core_port"></a> [existing\_helix\_core\_port](#input\_existing\_helix\_core\_port) | Existing helix core port for locust clients to use for P4PORT | `string` | `"1666"` | no |
| <a name="input_existing_helix_core_username"></a> [existing\_helix\_core\_username](#input\_existing\_helix\_core\_username) | Existing helix core username for locust clients to use for P4USER | `string` | `""` | no |
| <a name="input_existing_public_subnet"></a> [existing\_public\_subnet](#input\_existing\_public\_subnet) | Existing public subnet ID to use for EC2 deployments | `string` | `""` | no |
| <a name="input_existing_sg_ids"></a> [existing\_sg\_ids](#input\_existing\_sg\_ids) | Existing security group ID to use for network connectivity between locust client machines and Helix Core | `list(string)` | `[]` | no |
| <a name="input_existing_vpc"></a> [existing\_vpc](#input\_existing\_vpc) | Whether or not to use an existing VPC or create one | `bool` | `false` | no |
| <a name="input_existing_vpc_id"></a> [existing\_vpc\_id](#input\_existing\_vpc\_id) | Existing VPC ID to use for EC2 deployments | `string` | `""` | no |
| <a name="input_helix_core_commit_benchmark_username"></a> [helix\_core\_commit\_benchmark\_username](#input\_helix\_core\_commit\_benchmark\_username) | Username to use when running benchmark against Helix Core | `string` | `"bruno"` | no |
| <a name="input_helix_core_commit_instance_type"></a> [helix\_core\_commit\_instance\_type](#input\_helix\_core\_commit\_instance\_type) | The type of instance to start. | `string` | `"c5.xlarge"` | no |
| <a name="input_helix_core_commit_username"></a> [helix\_core\_commit\_username](#input\_helix\_core\_commit\_username) | Username to use for administoring Helix Core | `string` | `"perforce"` | no |
| <a name="input_ingress_cidrs_1666"></a> [ingress\_cidrs\_1666](#input\_ingress\_cidrs\_1666) | CIDR blocks to whitelist for Helix Core access | `string` | `""` | no |
| <a name="input_ingress_cidrs_22"></a> [ingress\_cidrs\_22](#input\_ingress\_cidrs\_22) | CIDR blocks to whitelist for SSH access | `string` | `""` | no |
| <a name="input_ingress_cidrs_locust"></a> [ingress\_cidrs\_locust](#input\_ingress\_cidrs\_locust) | CIDR blocks to whitelist for SSH access | `string` | `""` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Key name of the Key Pair to use for the instance. | `string` | n/a | yes |
| <a name="input_log_volume_iops"></a> [log\_volume\_iops](#input\_log\_volume\_iops) | How many IOPS to create the Log volume with. | `number` | `null` | no |
| <a name="input_log_volume_size"></a> [log\_volume\_size](#input\_log\_volume\_size) | Volume size for Log volume | `number` | `50` | no |
| <a name="input_log_volume_throughput"></a> [log\_volume\_throughput](#input\_log\_volume\_throughput) | Volume throughput for Log volume (only valid for volume type GP3) | `number` | `null` | no |
| <a name="input_log_volume_type"></a> [log\_volume\_type](#input\_log\_volume\_type) | Volume type for Log volume | `string` | `"gp3"` | no |
| <a name="input_metadata_volume_iops"></a> [metadata\_volume\_iops](#input\_metadata\_volume\_iops) | How many IOPS to create the Metadata volume with. | `number` | `null` | no |
| <a name="input_metadata_volume_size"></a> [metadata\_volume\_size](#input\_metadata\_volume\_size) | Volume size for Metadata volume | `number` | `50` | no |
| <a name="input_metadata_volume_throughput"></a> [metadata\_volume\_throughput](#input\_metadata\_volume\_throughput) | Volume throughput for Metadata volume (only valid for volume type GP3) | `number` | `null` | no |
| <a name="input_metadata_volume_type"></a> [metadata\_volume\_type](#input\_metadata\_volume\_type) | Volume type for Metadata volume | `string` | `"gp3"` | no |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | If true, the Helix Core EC2 instance will have detailed monitoring enabled. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on EC2 instance | `string` | `""` | no |
| <a name="input_number_locust_workers"></a> [number\_locust\_workers](#input\_number\_locust\_workers) | Number of Locust worker threads | `number` | `12` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Who is the owner of this infrastructure?  This value will be applied as a tag to all resources. | `string` | n/a | yes |
| <a name="input_p4benchmark_github_branch"></a> [p4benchmark\_github\_branch](#input\_p4benchmark\_github\_branch) | GitHub project branch name | `string` | `"main"` | no |
| <a name="input_p4benchmark_github_project"></a> [p4benchmark\_github\_project](#input\_p4benchmark\_github\_project) | GitHub project name | `string` | `"p4benchmark"` | no |
| <a name="input_p4benchmark_github_project_owner"></a> [p4benchmark\_github\_project\_owner](#input\_p4benchmark\_github\_project\_owner) | GitHub owner of the p4benchmark project | `string` | `"rcowham"` | no |
| <a name="input_p4benchmark_os_user"></a> [p4benchmark\_os\_user](#input\_p4benchmark\_os\_user) | What user Ansible should use for authenticating to all hosts | `string` | `"perforce"` | no |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | Private IP address to associate with the instance in a VPC.  Leave null to allow DHCP to assign IP address. | `string` | `null` | no |
| <a name="input_s3_checkpoint_bucket"></a> [s3\_checkpoint\_bucket](#input\_s3\_checkpoint\_bucket) | Name of the S3 bucket that contains checkpoints | `string` | `""` | no |
| <a name="input_volumes_encrypted"></a> [volumes\_encrypted](#input\_volumes\_encrypted) | Wether to encrypt the volumes with KMS.  If this is set to true kms\_key\_id must also me set. | `bool` | `false` | no |
| <a name="input_volumes_kms_key_id"></a> [volumes\_kms\_key\_id](#input\_volumes\_kms\_key\_id) | KMS key ID to use to encrypt the volumes.  This must be set if `volumes_encrypted` is true | `string` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block to use for AWS VPC.  Subnets will be automatically calculated from this block. | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_driver_public_ip"></a> [driver\_public\_ip](#output\_driver\_public\_ip) | Public IP address of the driver EC2 instance |
| <a name="output_helix_core_commit_instance_id"></a> [helix\_core\_commit\_instance\_id](#output\_helix\_core\_commit\_instance\_id) | Helix Core Instance ID - This is the password for the perforce user |
| <a name="output_helix_core_commit_private_ip"></a> [helix\_core\_commit\_private\_ip](#output\_helix\_core\_commit\_private\_ip) | Helix Core private IP address |
| <a name="output_helix_core_commit_public_ip"></a> [helix\_core\_commit\_public\_ip](#output\_helix\_core\_commit\_public\_ip) | Helix Core public IP address |
| <a name="output_locust_client_private_ips"></a> [locust\_client\_private\_ips](#output\_locust\_client\_private\_ips) | Array of private IP addresses for the Locust client EC2 instances |
| <a name="output_locust_client_public_ips"></a> [locust\_client\_public\_ips](#output\_locust\_client\_public\_ips) | Array of public IP addresses for the Locust client EC2 instances |
<!-- END_TF_DOCS -->