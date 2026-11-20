output "project_id" {
  description = "The UUID of the newly created Projects 2.0 project"
  value       = nutanix_project_v2.this.ext_id
}