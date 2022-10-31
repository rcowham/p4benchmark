
# P4 Benchmark Terraform

- [Terraform Variables](#terraform-variables)
- [`.envrc` file](#envrc-file)
- [Deployment](#deployment)
  - [AWS](#aws)
- [Variables](#variables)
- [Running createfiles.py](#running-createfilespy)
- [Outputs](#outputs)
- [TODO](#todo)


This project will create all required infrastructure to run p4benchmark in the cloud.

Subdirectories are each individual terraform project that are specific to a cloud provider.




## Terraform Variables



## `.envrc` file

I recommend using `direnv` to automatically set/unset environment variables.

Terraform variables can bet set via environment variables with this syntax

`TF_VAR_foo` where `foo` is the name of the Terraform variable.


Here is example of my `.envrc` file for this project:

```
export TF_VAR_owner="Andy Boutte"
export TF_VAR_key_name="aboutte"

export TF_VAR_ingress_cidrs_1666="162.244.43.81/32"
export TF_VAR_ingress_cidrs_22="162.244.43.81/32"
export TF_VAR_ingress_cidrs_locust="162.244.43.81/32"
```

## Deployment

```
terraform apply
terraform destroy
```

### AWS

For AWS deployments the following deployment options are available:

1) terraform creates VPC, Helix Core, Locust Client VMs, and a runner VM to orchestrate the benchmarking
2) terraform creates VPC, Locust Client VMs, and a runner VM to orchestrate the benchmarking.  In this scenario you must provide Helix Core.
3) terraform creates Locust Client VMs, and a runner VM to orchestrate the benchmarking.  In this scenario you must provide the VPC and Helix Core.

For #2 you will need to provide the following terraform variables:

```
export TF_VAR_existing_helix_core="true"

export TF_VAR_existing_helix_core_ip="10.0.0.56"
export TF_VAR_existing_helix_core_username="perforce"
export TF_VAR_existing_helix_core_password="i-01f6660de3c2a54a1"
```

For #3 you will need to provide the following terraform variables:

```
export TF_VAR_existing_vpc="true"
export TF_VAR_existing_helix_core="true"

export TF_VAR_existing_vpc_id="vpc-0d55f456b91720d42"
export TF_VAR_existing_public_subnet="subnet-004c35d9dada0fddb"
export TF_VAR_existing_az="us-east-1a"
export TF_VAR_existing_sg_ids='["sg-098bcb18177eb13df"]'

export TF_VAR_existing_helix_core_ip="10.0.0.56"
export TF_VAR_existing_helix_core_username="perforce"
export TF_VAR_existing_helix_core_password="i-01f6660de3c2a54a1"
```

## Variables

See README.md in the cloud specific directory for variables

## Running createfiles.py

The create files script can be run N number of times in two different ways:

1) The terraform variable `createfile_configs` is a list of maps which allow you to run the script N number of times, each different configurations
2) If, post deployment, you want to run create files again use the following commands to taint the terraform resources so they run again

```
terraform taint null_resource.run_create_files[0]
terraform taint null_resource.apply_p4d_configurables
terraform taint null_resource.remove_p4d_configurables
terraform apply
```

## Outputs

See README.md in the cloud specific directory for outputs


## TODO 

[ ] support restore depot data and checkpoint at deploy time