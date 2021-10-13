# Flower cloud setup

## Instructions
On your local machine, install Terraform (based on instructions in the
[Terraform Docs](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/docker-get-started)).

```shell
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

To launch VMs, first set the correct environment variables using
```shell
source <project_name>_openrc.sh
```
similarly to what was done in assignment 2.

Also create `secret.tfvars` in the project root, and add the line below to it, replacing `YOUR_KEY_PAIR_NAME` with the
name of your OpenStack key pair.
```terraform
key_pair = "YOUR_KEY_PAIR_NAME"
```

Make sure you are in the project root directory, and then run
```shell
terraform init
```
followed by
```shell
terraform apply -var-file="secret.tfvars"
```
The VMs should now have launched.

To remove the VMs, use
```shell
terraform destroy
```