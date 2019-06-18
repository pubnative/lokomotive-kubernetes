# Discrete DNS records for each controller's private IPv4 for etcd usage
locals {
  base_domain        = "${join(".", compact(split(".", var.dns_zone)))}"
  domain             = "${format("api.%s.%s", var.cluster_name, local.base_domain)}"
  internal_domain    = "${format("internal.%s.%s", var.cluster_name, local.base_domain)}"
  etcd_domain_format = "etcd-%d.%s"
  domain_ttl         = "${var.dns_zone_ttl}"
}

resource "aws_route53_record" "etcds" {
  count = "${var.controller_count}"

  # DNS Zone where record should be created
  zone_id = "${var.dns_zone_id}"

  name = "${format(local.etcd_domain_format, count.index, var.cluster_name)}"
  type = "A"
  ttl  = "${local.domain_ttl}"

  # private IPv4 address for etcd
  records = ["${element(packet_device.controllers.*.access_private_ipv4, count.index)}"]
}

# DNS record for the API servers
resource "aws_route53_record" "apiservers" {
  count   = "${var.controller_count == 0 ? 0 : 1}"
  zone_id = "${var.dns_zone_id}"

  name = "${local.domain}"
  type = "A"
  ttl  = "${local.domain_ttl}"

  # TODO - verify that a multi-controller setup actually works
  records = ["${packet_device.controllers.*.access_public_ipv4}"]
}

resource "aws_route53_record" "apiservers_private" {
  count   = "${var.controller_count == 0 ? 0 : 1}"
  zone_id = "${var.dns_zone_id}"

  name = "${local.internal_domain}"
  type = "A"
  ttl  = "${local.domain_ttl}"

  # TODO - verify that a multi-controller setup actually works
  records = ["${packet_device.controllers.*.access_private_ipv4}"]
}
