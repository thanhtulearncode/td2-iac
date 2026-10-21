data "openstack_images_image_v2" "ubuntu" {
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "k3s" {
  name = var.flavor_name
}

data "openstack_networking_network_v2" "asl_net" {
  name = var.private_network
}

data "openstack_networking_subnet_v2" "asl_subnet" {
  name       = "asl-subnet"
  network_id = data.openstack_networking_network_v2.asl_net.id
}

data "openstack_networking_network_v2" "public" {
  name = var.public_network
}

data "openstack_compute_keypair_v2" "asl_key" {
  name = var.keypair_name
}
