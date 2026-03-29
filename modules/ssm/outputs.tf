output "session_manager_document_name" {
  description = "Name of the SSM Session Manager configuration document."
  value       = aws_ssm_document.session_manager.name
}
