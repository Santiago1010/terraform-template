output "instance_id" {
  description = "ID of the Vault EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.vault.id
}

output "private_ip" {
  description = "Private IP of the Vault instance. Used by services to connect to Vault API."
  value       = aws_instance.vault.private_ip
}

output "sg_id" {
  description = "ID of the Vault security group. Reference this to allow access from specific services."
  value       = aws_security_group.vault.id
}

output "data_volume_id" {
  description = "ID of the EBS data volume. Useful for snapshots and backup automation."
  value       = aws_ebs_volume.vault_data.id
}
