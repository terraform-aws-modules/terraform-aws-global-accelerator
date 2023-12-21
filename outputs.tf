################################################################################
# Accelerator
################################################################################

output "id" {
  description = "The Amazon Resource Name (ARN) of the accelerator"
  value       = try(aws_globalaccelerator_accelerator.this[0].id, "")
}

output "dns_name" {
  description = "The DNS name of the accelerator"
  value       = try(aws_globalaccelerator_accelerator.this[0].dns_name, "")
}

output "dual_stack_dns_name" {
  description = "The DNS name that Global Accelerator creates that points to a dual-stack accelerator's four static IP addresses: two IPv4 addresses and two IPv6 addresses"
  value       = try(aws_globalaccelerator_accelerator.this[0].dual_stack_dns_name, "")
}

output "hosted_zone_id" {
  description = "The Global Accelerator Route 53 zone ID that can be used to route an Alias Resource Record Set to the Global Accelerator"
  value       = try(aws_globalaccelerator_accelerator.this[0].hosted_zone_id, "")
}

output "ip_sets" {
  description = "IP address set associated with the accelerator"
  value       = try(aws_globalaccelerator_accelerator.this[0].ip_sets, {})
}

################################################################################
# Listener(s)
################################################################################

output "listeners" {
  description = "Map of listeners created and their associated attributes"
  value       = aws_globalaccelerator_listener.this
}

################################################################################
# Endpoing Group(s)
################################################################################

output "endpoint_groups" {
  description = "Map of endpoints created and their associated attributes"
  value       = aws_globalaccelerator_endpoint_group.this
}
