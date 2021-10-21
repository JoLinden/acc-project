terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

provider "openstack" {
  auth_url    = "https://east-1.cloud.snic.se:5000/v3"
}

# Fetch floating IPs for the two VMs
resource "openstack_networking_floatingip_v2" "floating-ips" {
  pool = "Public External IPv4 Network"
  count = var.clients + 1
}

# Set up server
resource "openstack_compute_instance_v2" "g5-flower-server" {
  name            = "g5-flower-server${var.instance_suffix}"
  image_name      = "Ubuntu 18.04"
  image_id        = "0b7f5fb5-a25c-48b6-8578-06dbfa160723"
  flavor_name     = "ssc.xsmall"
  key_pair        = var.key_pair
  security_groups = ["default", "group-5"]
  user_data = file("cloud-config-server.txt")

  network {
    name = "UPPMAX 2021/1-5 Internal IPv4 Network"
  }
}

# Give server a floating IP and upload files
resource "openstack_compute_floatingip_associate_v2" "server-ip-associate" {
  floating_ip = openstack_networking_floatingip_v2.floating-ips[0].address
  instance_id = openstack_compute_instance_v2.g5-flower-server.id
  depends_on = [
    openstack_compute_instance_v2.g5-flower-server,
    openstack_networking_floatingip_v2.floating-ips
  ]

  provisioner "file" {
    source        = "server/"
    destination   = "/home/ubuntu/"

    connection {
      user        = "ubuntu"
      host        = openstack_compute_floatingip_associate_v2.server-ip-associate.floating_ip
    }
  }
}


# Set up client
resource "openstack_compute_instance_v2" "g5-flower-client" {
  count           = var.clients
  name            = format("g5-flower-client${var.instance_suffix}-%s", count.index)
  image_name      = "Ubuntu 18.04"
  image_id        = "0b7f5fb5-a25c-48b6-8578-06dbfa160723"
  flavor_name     = "ssc.xsmall.highmem"
  key_pair        = var.key_pair
  security_groups = ["default", "group-5"]
  depends_on = [
    openstack_compute_instance_v2.g5-flower-server
  ]
  user_data = file("cloud-config-client.txt")

  network {
    name = "UPPMAX 2021/1-5 Internal IPv4 Network"
  }
}

# Give client a floating IP and upload files
resource "openstack_compute_floatingip_associate_v2" "client-ip-associate" {
  count = var.clients
  floating_ip = openstack_networking_floatingip_v2.floating-ips[count.index + 1].address
  instance_id = openstack_compute_instance_v2.g5-flower-client[count.index].id

  depends_on  = [
    openstack_compute_instance_v2.g5-flower-client,
    openstack_networking_floatingip_v2.floating-ips
  ]

  provisioner "file" {
    source      = "client/"
    destination = "/home/ubuntu/"

    connection {
      user = "ubuntu"
      host = self.floating_ip
    }
  }
}

# Set configuration variables for the clients
resource "null_resource" "update-client-config" {
  count = var.clients

  depends_on = [
    openstack_compute_floatingip_associate_v2.client-ip-associate,
    openstack_compute_floatingip_associate_v2.server-ip-associate
  ]

  connection {
    user = "ubuntu"
    host = openstack_compute_floatingip_associate_v2.client-ip-associate[count.index].floating_ip
  }
  provisioner "remote-exec" {
    inline = [
      "echo \"server_ip = '${openstack_compute_instance_v2.g5-flower-server.access_ip_v4}'\" > /home/ubuntu/config.py",
      "echo \"n_clients = ${var.clients}\" >> /home/ubuntu/config.py",
      "echo \"client_id = ${count.index}\" >> /home/ubuntu/config.py",
    ]
  }
}

# Set server_ip of the client config file
resource "null_resource" "update-server-config" {
  depends_on = [
    openstack_compute_floatingip_associate_v2.server-ip-associate
  ]

  connection {
    user = "ubuntu"
    host = openstack_compute_floatingip_associate_v2.server-ip-associate.floating_ip
  }
  provisioner "remote-exec" {
    inline = [
      "echo \"n_clients = ${var.clients}\" > /home/ubuntu/config.py"
    ]
  }
}