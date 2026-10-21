# --- VM K3s ---
resource "openstack_compute_instance_v2" "k3s" {
  name            = "k3s-${var.login}"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.k3s.id
  key_pair        = data.openstack_compute_keypair_v2.asl_key.name
  security_groups = [openstack_networking_secgroup_v2.k3s.name]

  network {
    name = data.openstack_networking_network_v2.asl_net.name
  }

  config_drive = true
  user_data    = file("${path.module}/cloud-init.yaml")

  metadata = {
    owner   = var.login
    project = "asl"
    td      = "td2"
  }
}

# --- IP flottante ---
resource "openstack_networking_floatingip_v2" "k3s_fip" {
  pool = data.openstack_networking_network_v2.public.name
}

# --- Port reseau de la VM (cote Neutron) ---
data "openstack_networking_port_v2" "k3s_port" {
  device_id  = openstack_compute_instance_v2.k3s.id
  network_id = data.openstack_networking_network_v2.asl_net.id
}

# --- Association FIP <-> port VM ---
resource "openstack_networking_floatingip_associate_v2" "k3s_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.k3s_fip.address
  port_id     = data.openstack_networking_port_v2.k3s_port.id
}
