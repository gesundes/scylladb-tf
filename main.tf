terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

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

data "aws_ami" "scylladb_ami" {
  most_recent = true

  filter {
    name = "name"
    values = ["ScyllaDB ${var.scylladb_version}"]
  }
}

resource "aws_security_group" "scylladb_all" {
  name        = "scylladb_all"
  description = "Will allow all inbound traffic from your public IP"

  tags = {
    Name = "ScyllaDB"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_inbound_traffic_ipv4" {
  security_group_id = aws_security_group.scylladb_all.id
  cidr_ipv4         = var.your_public_network
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_internal_traffic_ipv4" {
  security_group_id            = aws_security_group.scylladb_all.id
  referenced_security_group_id = aws_security_group.scylladb_all.id
  ip_protocol                  = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.scylladb_all.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "scylladb_seed" {
  ami           = data.aws_ami.scylladb_ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.scylladb_all.id]
  key_name      = var.ssh_key_name

  user_data = <<EOF
scylla_yaml:
  cluster_name: test-cluster
  experimental: true
start_scylla_on_first_boot: true
EOF

  tags = {
    Name = "ScyllaDB seed"
  }
}

resource "aws_instance" "scylladb_host" {
  ami           = data.aws_ami.scylladb_ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.scylladb_all.id]
  key_name      = var.ssh_key_name

  user_data = <<EOF
scylla_yaml:
  cluster_name: test-cluster
  experimental: true
  seed_provider:
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
        - seeds: ${aws_instance.scylladb_seed.private_ip}
start_scylla_on_first_boot: true
EOF

  tags = {
    Name = "ScyllaDB host"
  }

  count = var.number_of_regular_hosts
}

output "scylladb_seed_public_ip" {
  value       = aws_instance.scylladb_seed.public_ip
  description = "ScyllaDB seed public IP address."
}

output "scylladb_host_public_ip" {
  value = [aws_instance.scylladb_host.*.public_ip]
  description = "ScyllaDB host public IP addresses."
}
