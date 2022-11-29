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

2. Create a resource group to hold your public key:
```bash
export key_name="fgiordano"
export key_resource_group_name="fgiordano-keys"
location=eastus # Tweak as needed

az group create --name $key_resource_group_name --location $location
az sshkey create --name $key_name --resource-group $key_resource_group_name
```

Notice the new private key has been saved to `~/.ssh/<id>` 

3. Add the SSH Key to your Agent:
```bash
# Make sure your Agent is runnning
eval "$(ssh-agent -s)"

ssh-add "~\.ssh\<id>"
```

4. Set the Terraform variables related to the SSH Key
```bash
# Showing only those specific to the SSH Key
export TF_VAR_key_name=$key_name
export TF_VAR_key_resource_group_name=$key_resource_group_name
```

5. Run Terraform
```bash
terraform apply
```