# P4 Benchmark - Azure

## Setup

Before runnning the Terraform scripts, you'll need to create the SSH Key pair to assign to the machines and add it to your SSH Agent.

_Note: if you are on Windows, execute all of the following commands in Git Bash to ensure compatibility._

1. Make sure your `az` client is correctly installed and configured:

```bash
az login

# Check whether your chosen subscription is correct
az account show
```

2. _Once per subscription_, you'll have to enable EncryptionAtHost for the VMs and accept the Terms & Conditions for the Perforce image:

```bash
az feature register --namespace Microsoft.Compute --name EncryptionAtHost

az vm image terms accept --urn perforce:rockylinux8:8-gen2:8.6.2022060701
```

3. Create a resource group to hold your public key:

```bash
export key_name="fgiordano"
export key_resource_group_name="fgiordano-keys"
location=eastus # Tweak as needed

az group create --name $key_resource_group_name --location $location
az sshkey create --name $key_name --resource-group $key_resource_group_name
```

Notice the new private key has been saved to `~/.ssh/<id>`

4. Add the SSH Key to your Agent:

```bash
# Make sure your Agent is runnning
eval "$(ssh-agent -s)"

ssh-add "~\.ssh\<id>"
```

5. Set the Terraform variables

Terraform variables can bet set via environment variables with this syntax TF_VAR_foo where foo is the name of the Terraform variable.

You can configure the variables by creating the file `terraform.tfvars` within this folder with the following:

```
owner                         = "Christian Cabrer"
key_name                      = "ccabrer"
key_resource_group_name       = "ccabrer-keys"
```

Or you can do it using the .envrc file:

```bash
export TF_VAR_owner="Christian Cabrer"
export TF_VAR_key_name="ccabrer"

# SSH Key
export TF_VAR_key_name=$key_name
export TF_VAR_key_resource_group_name=$key_resource_group_name

# Ip whitelist
export TF_VAR_ingress_cidrs_22="200.80.77.193"
export TF_VAR_ingress_cidrs_1666="200.80.77.193"
```

6. Run Terraform

```bash
terraform apply
```
