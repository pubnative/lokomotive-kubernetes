locals {
  pool_name       = "${replace(var.pool_name, "_", "-")}"
  hostname_prefix = "${join("-", compact(list(var.cluster_name, local.pool_name, "worker")))}"
}

resource "packet_device" "nodes" {
  count            = "${var.count}"
  hostname         = "${local.hostname_prefix}-${count.index}"
  plan             = "${var.type}"
  facilities       = ["${var.facility}"]
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = "${var.project_id}"
  ipxe_script_url  = "${var.ipxe_script_url}"
  always_pxe       = "false"
  user_data        = "${data.ct_config.install-ignitions.rendered}"
  ip_address_types = ["private_ipv4", "public_ipv4"]

  # If not present in the map, it uses ${var.reservation_ids_default}
  hardware_reservation_id = "${lookup(var.reservation_ids, format("worker-%v", count.index), var.reservation_ids_default)}"
}

# These configs are used for the fist boot, to run flatcar-install
data "ct_config" "install-ignitions" {
  content = "${data.template_file.install.rendered}"
}

data "template_file" "install" {
  template = "${file("${path.module}/cl/install.yaml.tmpl")}"

  vars {
    os_channel           = "${var.os_channel}"
    os_version           = "${var.os_version}"
    flatcar_linux_oem    = "packet"
    ssh_keys             = "${jsonencode("${var.ssh_keys}")}"
    postinstall_ignition = "${data.ct_config.ignitions.rendered}"
    setup_raid           = "${var.setup_raid}"
  }
}

resource "packet_bgp_session" "bgp" {
  count          = "${var.enable_bgp ? var.count : 0}"
  device_id      = "${packet_device.nodes.*.id[count.index]}"
  address_family = "ipv4"
}

data "ct_config" "ignitions" {
  content  = "${data.template_file.configs.rendered}"
  platform = "packet"
}

data "template_file" "configs" {
  template = "${file("${path.module}/cl/worker.yaml.tmpl")}"

  vars {
    kubeconfig            = "${indent(10, "${var.kubeconfig}")}"
    ssh_keys              = "${jsonencode("${var.ssh_keys}")}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    kube_version          = "${var.kube_version}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
    worker_labels         = "${var.labels}"
    taints                = "${var.taints}"
  }
}
