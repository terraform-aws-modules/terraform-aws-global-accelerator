################################################################################
# Custom Routing Accelerator
################################################################################

output "id" {
  description = "The Amazon Resource Name (ARN) of the custom routing accelerator"
  value       = try(aws_globalaccelerator_custom_routing_accelerator.this[0].id, "")
}

output "arn" {
  description = "The Amazon Resource Name (ARN) of the custom routing accelerator"
  value       = try(aws_globalaccelerator_custom_routing_accelerator.this[0].arn, "")
}

output "dns_name" {
  description = "The DNS name of the custom routing accelerator"
  value       = try(aws_globalaccelerator_custom_routing_accelerator.this[0].dns_name, "")
}

output "hosted_zone_id" {
  description = "The Global Accelerator Route 53 zone ID that can be used to route an Alias Resource Record Set to the Global Accelerator"
  value       = try(aws_globalaccelerator_custom_routing_accelerator.this[0].hosted_zone_id, "")
}

output "ip_sets" {
  description = "IP address set associated with the custom routing accelerator"
  value       = try(aws_globalaccelerator_custom_routing_accelerator.this[0].ip_sets, {})
}

################################################################################
# Custom Routing Listener(s)
################################################################################

output "listeners" {
  description = "Map of listeners created and their associated attributes"
  value       = aws_globalaccelerator_custom_routing_listener.this
}

################################################################################
# Custom Routing Endpoint Group(s)
################################################################################

output "endpoint_groups" {
  description = "Map of endpoints created and their associated attributes"
  value       = aws_globalaccelerator_custom_routing_endpoint_group.this
}
