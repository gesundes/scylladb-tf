output "scylladb_seed_public_ip" {
  value       = aws_instance.scylladb_seed.public_ip
  description = "Public IP address of the ScyllaDB seed host."
}

output "scylladb_host_public_ip" {
  value = [aws_instance.scylladb_host.*.public_ip]
  description = "Public IP addresses of ScyllaDB regular hosts."
}