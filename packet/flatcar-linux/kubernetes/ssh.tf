# Secure copy etcd TLS assets to controllers.
resource "null_resource" "copy-controller-secrets" {
  count = "${var.controller_count}"

  connection {
    type    = "ssh"
    host    = "${element(packet_device.controllers.*.access_public_ipv4, count.index)}"
    user    = "core"
    timeout = "120m"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_ca_cert}"
    destination = "$HOME/etcd-client-ca.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_client_cert}"
    destination = "$HOME/etcd-client.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_client_key}"
    destination = "$HOME/etcd-client.key"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_server_cert}"
    destination = "$HOME/etcd-server.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_server_key}"
    destination = "$HOME/etcd-server.key"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_peer_cert}"
    destination = "$HOME/etcd-peer.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_peer_key}"
    destination = "$HOME/etcd-peer.key"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/ssl/etcd/etcd",
      "sudo mv etcd-client* /etc/ssl/etcd/",
      "sudo cp /etc/ssl/etcd/etcd-client-ca.crt /etc/ssl/etcd/etcd/server-ca.crt",
      "sudo mv etcd-server.crt /etc/ssl/etcd/etcd/server.crt",
      "sudo mv etcd-server.key /etc/ssl/etcd/etcd/server.key",
      "sudo cp /etc/ssl/etcd/etcd-client-ca.crt /etc/ssl/etcd/etcd/peer-ca.crt",
      "sudo mv etcd-peer.crt /etc/ssl/etcd/etcd/peer.crt",
      "sudo mv etcd-peer.key /etc/ssl/etcd/etcd/peer.key",
      "sudo chown -R etcd:etcd /etc/ssl/etcd",
      "sudo chmod -R 500 /etc/ssl/etcd",
    ]
  }
}

# Secure copy bootkube assets to ONE controller and start bootkube to perform
# one-time self-hosted cluster bootstrapping.
resource "null_resource" "bootkube-start" {
  count = "${var.controller_count == 0 ? 0 : 1}"

  depends_on = [
    "module.bootkube",
    "aws_route53_record.apiservers_private",
    "null_resource.copy-controller-secrets",
  ]

  connection {
    type    = "ssh"
    host    = "${packet_device.controllers.0.access_public_ipv4}"
    user    = "core"
    timeout = "15m"
  }

  provisioner "file" {
    source      = "${var.asset_dir}"
    destination = "$HOME/assets"
  }

  provisioner "file" {
    content     = "${data.template_file.host_protection_policy.rendered}"
    destination = "$HOME/assets/manifests-networking/calico-policy.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv $HOME/assets /opt/bootkube",
      "sudo systemctl start bootkube",
      "sudo shutdown -r +1",
    ]
  }
}

data "template_file" "controller_host_endpoints" {
  count    = "${var.controller_count}"
  template = "${file("${path.module}/calico/host_endpoints.yaml.tmpl")}"

  vars {
    node_name = "${element(packet_device.controllers.*.hostname, count.index)}"
    node_type = "controller"
  }
}

data "template_file" "worker_host_endpoints" {
  count    = "${var.worker_count}"
  template = "${file("${path.module}/calico/host_endpoints.yaml.tmpl")}"

  vars {
    node_name = "${element("${var.worker_nodes_hostnames}", count.index)}"
    node_type = "worker"
  }
}

data "template_file" "host_protection_policy" {
  template = "${file("${path.module}/calico/calico-policy.yaml.tmpl")}"

  vars = {
    controller_host_endpoints = "${join("\n", data.template_file.controller_host_endpoints.*.rendered)}"
    worker_host_endpoints     = "${join("\n", data.template_file.worker_host_endpoints.*.rendered)}"
    management_cidrs          = "${jsonencode("${var.management_cidrs}")}"
    cluster_internal_cidrs    = "${jsonencode(list("${var.node_private_cidr}", "${var.pod_cidr}", "${var.service_cidr}"))}"
    etcd_server_cidrs         = "${jsonencode("${packet_device.controllers.*.access_private_ipv4}")}"
    node_ips                  = "${jsonencode(concat("${packet_device.controllers.*.access_private_ipv4}", "${var.worker_nodes_public_ipv4s}"))}"
  }
}
