# DNS records

variable "cluster_name" {
  type        = "string"
  description = "Unique cluster name"
}

# Nodes

variable "os_image_unpacked" {
  type        = "string"
  description = "Path to unpacked Flatcar image flatcar_production_qemu_image.img (probably after a qemu-img resize IMG +5G)"
}

variable "controller_count" {
  type        = "string"
  default     = "1"
  description = "Number of controllers (i.e. masters)"
}

variable "machine_domain" {
  type = "string"
  description = "Machine domain"
}

variable "node_ip_pool" {
  type = "string"
  default = "192.168.192.0/24"
  description = "Unique VM IP CIDR"
}

# Configuration

variable "ssh_keys" {
  type        = "list"
  description = "SSH public keys for user 'core'"
}

variable "asset_dir" {
  description = "Path to a directory where generated assets should be placed (contains secrets)"
  type        = "string"
}

variable "networking" {
  description = "Choice of networking provider (flannel or calico)"
  type        = "string"
  default     = "calico"
}

variable "network_mtu" {
  description = "CNI interface MTU (applies to calico only)"
  type        = "string"
  default     = "1480"
}

variable "network_ip_autodetection_method" {
  description = "Method to autodetect the host IPv4 address (applies to calico only)"
  type        = "string"
  default     = "first-found"
}

variable "pod_cidr" {
  description = "CIDR IPv4 range to assign Kubernetes pods"
  type        = "string"
  default     = "10.1.0.0/16"
}

variable "service_cidr" {
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for coredns.
EOD

  type    = "string"
  default = "10.2.0.0/16"
}

variable "cluster_domain_suffix" {
  description = "Queries for domains with the suffix will be answered by coredns. Default is cluster.local (e.g. foo.default.svc.cluster.local) "
  type        = "string"
  default     = "cluster.local"
}

variable "enable_reporting" {
  type        = "string"
  description = "Enable usage or analytics reporting to upstreams (Calico)"
  default     = "false"
}

variable "enable_aggregation" {
  description = "Enable the Kubernetes Aggregation Layer (defaults to false)"
  type        = "string"
  default     = "false"
}
