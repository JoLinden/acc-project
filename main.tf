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

# key 
resource "openstack_compute_keypair_v2" "my-cloud-key" {
  name       = "stef-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgjz0c2tDJbVcgULgJR6BAyYI0rfQBk67tpR7cWyIPyd467j66GkXEwUhZRoEecGoLNqYLYyHcalV49BpvNrxif0oJxGNu/sUn9i1YLArBFDdJ0C9L0BbwK9p0hQkDJa4hEepj2R5o6W7fro55ueMIyJCJVJZk/3H0TIl5PYPxCArZRuiXw3QW4W2/MvnY/5vRydgrqv9TxSBLBTBvFfBjPHv3h9wxsh0TVRI1AIDXF/9W31di4uDtu68AavaDM/XrrfrFNPO0bVHxjCdZJi4nhM2+gJkRqdkZASl/VQUVuFs68bYaDW7IK3bTsqGLkkPu3uBrXPtZybMyhzZib1Bp"
}

# Fetch floating IPs for the two VMs
resource "openstack_networking_floatingip_v2" "floating-ips" {
  pool = "Public External IPv4 Network"
  count = 2
}

# Set up server
resource "openstack_compute_instance_v2" "g5-flower-server-b" {
  name            = "g5-flower-server-b"
  image_name      = "Ubuntu 18.04"
  image_id        = "0b7f5fb5-a25c-48b6-8578-06dbfa160723"
  flavor_name     = "ssc.xsmall"
  key_pair        = "${openstack_compute_keypair_v2.my-cloud-key.name}"
  security_groups = ["default", "group-5", "stefanos_sec_group"]


  network {
    name = "UPPMAX 2021/1-5 Internal IPv4 Network"
  }
}


# Give server a floating IP and upload files
resource "openstack_compute_floatingip_associate_v2" "server-ip-associate" {
  floating_ip = openstack_networking_floatingip_v2.floating-ips[0].address
  instance_id = openstack_compute_instance_v2.g5-flower-server-b.id
  depends_on = [
    openstack_compute_instance_v2.g5-flower-server-b,
    openstack_networking_floatingip_v2.floating-ips
  ]

  provisioner "file" {
    source        = "server/"
    destination   = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = openstack_compute_floatingip_associate_v2.server-ip-associate.floating_ip
      private_key = file("stefkeypair.pem")
    }
  }
}


# Set up client
resource "openstack_compute_instance_v2" "g5-flower-client-b" {
  name            = "g5-flower-client-b"
  image_name      = "Ubuntu 18.04"
  image_id        = "0b7f5fb5-a25c-48b6-8578-06dbfa160723"
  flavor_name     = "ssc.xsmall"
  key_pair        = "${openstack_compute_keypair_v2.my-cloud-key.name}"
  security_groups = ["default", "group-5", "stefanos_sec_group"]
  depends_on = [
    openstack_compute_instance_v2.g5-flower-server-b
  ]


  #personality {
  #  content = "server_ip = '${openstack_compute_instance_v2.g5-flower-server-b.access_ip_v4}'"
  #  file    = "/home/ubuntu/config.py"
  #}

  network {
    name = "UPPMAX 2021/1-5 Internal IPv4 Network"
  }
}

# Give client a floating IP and upload files
resource "openstack_compute_floatingip_associate_v2" "client-ip-associate" {
  floating_ip = openstack_networking_floatingip_v2.floating-ips[1].address
  instance_id = openstack_compute_instance_v2.g5-flower-client-b.id
  depends_on  = [
    openstack_compute_instance_v2.g5-flower-client-b,
    openstack_networking_floatingip_v2.floating-ips
  ]

  provisioner "file" {
    source      = "client/"
    destination = "/home/ubuntu/"

    connection {
      type = "ssh"
      user = "ubuntu"
      host = openstack_compute_floatingip_associate_v2.client-ip-associate.floating_ip
      private_key = file("stefkeypair.pem")
    }
  }
}

# Set server_ip of the client config file
resource "null_resource" "update-client-config" {
  depends_on = [
    openstack_compute_floatingip_associate_v2.client-ip-associate,
    openstack_compute_floatingip_associate_v2.server-ip-associate
  ]

  connection {
    type = "ssh"
    user = "ubuntu"
    host = openstack_compute_floatingip_associate_v2.client-ip-associate.floating_ip
    private_key = file("stefkeypair.pem")
  }
  provisioner "remote-exec" {
    inline = ["echo \" server_ip = '${openstack_compute_instance_v2.g5-flower-server-b.access_ip_v4}'\" > /home/ubuntu/config.py"]
  }
}