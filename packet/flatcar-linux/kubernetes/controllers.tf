resource "packet_device" "controllers" {
  count                   = "${var.controller_count}"
  hostname                = "${var.cluster_name}-controller-${count.index}"
  plan                    = "${var.controller_type}"
  facilities              = ["${var.facility}"]
  operating_system        = "custom_ipxe"
  billing_cycle           = "hourly"
  project_id              = "${var.project_id}"
  ipxe_script_url         = "${var.ipxe_script_url}"
  always_pxe              = "false"
  user_data               = "${element(data.ct_config.controller-install-ignitions.*.rendered, count.index)}"
  ip_address_types        = ["private_ipv4", "public_ipv4"]
  hardware_reservation_id = "${length(var.reservation_ids) > 0 ? element(concat(var.reservation_ids, list("")), count.index) : ""}"
}

data "ct_config" "controller-install-ignitions" {
  count   = "${var.controller_count}"
  content = "${element(data.template_file.controller-install.*.rendered, count.index)}"
}

data "template_file" "controller-install" {
  count    = "${var.controller_count}"
  template = "${file("${path.module}/cl/controller-install.yaml.tmpl")}"

  vars {
    os_channel           = "${var.os_channel}"
    os_version           = "${var.os_version}"
    flatcar_linux_oem    = "packet"
    ssh_keys             = "${jsonencode("${var.ssh_keys}")}"
    postinstall_ignition = "${element(data.ct_config.controller-ignitions.*.rendered, count.index)}"
  }
}

data "ct_config" "controller-ignitions" {
  count    = "${var.controller_count}"
  platform = "packet"
  content  = "${element(data.template_file.controller-configs.*.rendered, count.index)}"
}

data "template_file" "controller-configs" {
  count    = "${var.controller_count}"
  template = "${file("${path.module}/cl/controller.yaml.tmpl")}"

  vars {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = "etcd-${count.index}.${var.cluster_name}.${var.dns_zone}"

    # etcd0=https://etcd-0.cluster.example.com,etcd1=https://etcd-1.cluster.example.com,...
    etcd_initial_cluster = "${join(",", data.template_file.etcds.*.rendered)}"

    kubeconfig            = "${indent(10, module.bootkube.kubeconfig-kubelet)}"
    ssh_keys              = "${jsonencode("${var.ssh_keys}")}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
  }
}

# etcd0=https://etcd-0.cluster.example.com,etcd1=https://etcd-1.cluster.example.com,...
data "template_file" "etcds" {
  count    = "${var.controller_count}"
  template = "etcd$${index}=https://etcd-$${index}}.$${cluster_name}.$${dns_zone}:2380"

  vars {
    index        = "${count.index}"
    cluster_name = "${var.cluster_name}"
    dns_zone     = "${var.dns_zone}"
  }
}
