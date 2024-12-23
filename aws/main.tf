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

data "aws_ami" "scylladb_ami" {
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
