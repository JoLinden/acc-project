# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  auth_url    = "https://east-1.cloud.snic.se:5000/v3"
}

# Create a web server
resource "openstack_compute_instance_v2" "g5-flower-server" {
  name            = "g5-flower-server"
  image_name      = "Ubuntu 18.04"
  image_id        = "0b7f5fb5-a25c-48b6-8578-06dbfa160723"
  flavor_name     = "ssc.xsmall"
  key_pair        = var.key_pair
  security_groups = ["default", "group-5"]

  network {
    name = "UPPMAX 2021/1-5 Internal IPv4 Network"
  }
}

resource "openstack_compute_instance_v2" "g5-flower-client" {
  name            = "g5-flower-client"
  image_name      = "Ubuntu 18.04"
  image_id        = "0b7f5fb5-a25c-48b6-8578-06dbfa160723"
  flavor_name     = "ssc.xsmall"
  key_pair        = var.key_pair
  security_groups = ["default", "group-5"]

  network {
    name = "UPPMAX 2021/1-5 Internal IPv4 Network"
  }
}
resource "openstack_networking_floatingip_v2" "server-ip" {
  pool = "Public External IPv4 Network"
}

resource "openstack_compute_floatingip_associate_v2" "fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.server-ip.address
  instance_id = openstack_compute_instance_v2.g5-flower-server.id
}
