# Flower cloud setup 

## Getting started
All the commands in the instructions should be run on your local machine.

Clone the repository and move into the project directory
```shell
git clone https://github.com/JoLinden/acc-project.git
cd acc-project
```

Install Terraform (based on instructions in the
[Terraform Docs](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/docker-get-started)).

```shell
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

To launch the server and clients, first set the correct environment variables using
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
The instances should now have launched.

By default, 2 clients are launched. To change the number of clients, run
```shell
terraform apply -var-file="secret.tfvars" -var="clients=N"
```
where `N` is the number of clients you want to launch.

To remove the instances, use
```shell
terraform destroy
```

### Changing things
Whenever you make changes to the setup, you need to destroy the instances, and then recreate them using
`terraform apply` as described above. Some changes, such as introducing a new provider
(e.g. `openstack` or `null_resource`), might also require that you run `terraform init` again, you will be prompted to
do so when running `terraform apply` if that is the case.

## Project structure
The project is split up into two services, the server and the client, each with their own directory.

Running `terraform apply` will create one instance for the server, and one instance for each client.
It will then attach floating IPs to them, and move only the
needed files (`server/` and `client/`) for the services to the respective instances.

The Terraform configuration is mainly done in `main.tf`, but declaration of variables is done in `variables.tf`.