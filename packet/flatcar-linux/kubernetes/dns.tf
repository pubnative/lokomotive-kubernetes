# Discrete DNS records for each controller's private IPv4 for etcd usage
locals {
  domain          = "${format("api.%s", var.cluster_name)}"
  internal_domain = "${format("internal.%s", var.cluster_name)}"
}

resource "aws_route53_record" "etcds" {
  count = "${var.controller_count}"

  # DNS Zone where record should be created
  zone_id = "${var.dns_zone_id}"

  name = "${format("etcd-%d.%s", count.index, var.cluster_name)}"
  type = "A"
  ttl  = 300

  # private IPv4 address for etcd
  records = ["${element(packet_device.controllers.*.access_private_ipv4, count.index)}"]
}

# DNS record for the API servers
resource "aws_route53_record" "apiservers" {
  zone_id = "${var.dns_zone_id}"

  name = "${local.domain}"
  type = "A"
  ttl  = "300"

  # TODO - verify that a multi-controller setup actually works
  records = ["${packet_device.controllers.*.access_public_ipv4}"]
}

resource "aws_route53_record" "apiservers_private" {
  zone_id = "${var.dns_zone_id}"

  name = "${local.internal_domain}"
  type = "A"
  ttl  = "300"

  # TODO - verify that a multi-controller setup actually works
  records = ["${packet_device.controllers.*.access_private_ipv4}"]
}
