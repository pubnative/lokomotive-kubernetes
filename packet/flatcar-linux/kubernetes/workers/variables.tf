# Cluster

variable "cluster_name" {
  type        = "string"
  description = "Unique cluster name (prepended to dns_zone)"
  default     = ""
}

variable "project_id" {
  description = "Packet project ID (e.g. 405efe9c-cce9-4c71-87c1-949c290b27dc)"
}

# Nodes

variable "pool_name" {
  type        = "string"
  description = "Unique worker pool name (prepended to hostname)"
}

variable "count" {
  type        = "string"
  default     = "1"
  description = "Number of workers"
}

variable "type" {
  type        = "string"
  default     = "baremetal_0"
  description = "Packet instance type for workers"
}

# TODO: migrate to `templatefile` when Terraform `0.12` is out and use `{% for ~}`
# to avoid specifying `--node-labels` again when the var is empty.
variable "labels" {
  type        = "string"
  default     = ""
  description = "Custom labels to assign to worker nodes. Provide comma separated key=value pairs as labels. e.g. 'foo=oof,bar=,baz=zab'"
}

variable "taints" {
  type        = "string"
  default     = ""
  description = "Comma separated list of taints. eg. 'clusterType=staging:NoSchedule,nodeType=storage:NoSchedule'"
}

variable "ipxe_script_url" {
  type = "string"

  # Workaround. iPXE-booting Flatcar on Packet over HTTPS is failing due to a bug in iPXE.
  # This patch is supposed to fix this: http://git.ipxe.org/ipxe.git/commitdiff/b6ffe28a2
  # TODO Switch back to an iPXE script which installs Flatcar over HTTPS after iPXE on Packet is
  # updated to a version which contains the patch. Alterntaively, if Flatcar is introduced as an
  # official OS option on Packet, we could remove iPXE boot altogether.
  default = "https://raw.githubusercontent.com/kinvolk/flatcar-ipxe-scripts/no-https/packet.ipxe"

  description = "Location to load the pxe boot script from"
}

variable "facility" {
  type        = "string"
  description = "Packet facility to deploy the cluster in"
}

variable "os_channel" {
  type        = "string"
  default     = "stable"
  description = "Flatcar Linux channel to install from (stable, beta, alpha)"
}

variable "os_version" {
  type        = "string"
  default     = "current"
  description = "Flatcar Linux version to install (for example '2079.3.1' - see https://www.flatcar-linux.org/releases/)"
}

variable "cluster_domain_suffix" {
  description = "Queries for domains with the suffix will be answered by coredns. Default is cluster.local (e.g. foo.default.svc.cluster.local) "
  type        = "string"
  default     = "cluster.local"
}

variable "kubeconfig" {
  description = "Kubeconfig file"
  type        = "string"
}

variable "ssh_keys" {
  type        = "list"
  description = "SSH public keys for user 'core'"
}

variable "service_cidr" {
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for coredns.
EOD

  type    = "string"
  default = "10.3.0.0/16"
}

variable "setup_raid" {
  description = "Attempt to create a RAID 0 from extra disks to be used for persistent container storage. Valid values: 'true', 'false'"
  type        = "string"
  default     = "false"
}

variable "reservation_ids" {
  description = "Specify Packet hardware_reservation_id for instances. A map where the key format is 'worker-${index}' and the associated value is the reservation id string. Nodes not present in the map will use the value of reservation_ids_default var. Example: reservation_ids = { worker-0 = '<reservation_id>' }"
  type        = "map"
  default     = {}
}

variable "reservation_ids_default" {
  description = "Possible values: '' and 'next-available'. Value used for nodes not listed in the reservation_ids map. Note that using the empty string means using no hardware reservation and 'next-available' will choose any reservation that matches the instance type and facility this pool is running."
  type        = "string"
  default     = ""
}

variable "kube_version" {
  description = "Specify Kuberentes version. e.g v1.14.3"
  default     = "v1.14.3"
}

variable "enable_bgp" {
  description = "Enable BGP for device"
  default     = false
}
