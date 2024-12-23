variable "scylladb_version" {
  type        = string
  default     = "6.2.1"
  description = "The version of the ScyllaDB to install."
}

variable "your_public_network" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Your public static IP address or your provider network."
}

variable "instance_type" {
  type        = string
  default     = "i4i.large"
  description = "The AWS instance type."
}

variable "number_of_regular_hosts" {
  type        = number
  default     = 2
  description = "The number of the regular (not seed) hosts in a cluster."
}

variable "ssh_key_name" {
  type        = string
  default     = "my_ssh_key"
  description = "The name of your public SSH key uploaded to AWS."
}
