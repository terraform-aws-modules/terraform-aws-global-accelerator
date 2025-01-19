################################################################################
# Accelerator
################################################################################

output "id" {
  description = "The Amazon Resource Name (ARN) of the accelerator"
  value       = module.global_accelerator.id
}

output "arn" {
  description = "The Amazon Resource Name (ARN) of the accelerator"
  value       = module.global_accelerator.arn
}

output "dns_name" {
  description = "The DNS name of the accelerator"
  value       = module.global_accelerator.dns_name
}

output "hosted_zone_id" {
  description = "The Global Accelerator Route 53 zone ID that can be used to route an Alias Resource Record Set to the Global Accelerator"
  value       = module.global_accelerator.hosted_zone_id
}

output "ip_sets" {
  description = "IP address set associated with the accelerator"
  value       = module.global_accelerator.ip_sets
}

################################################################################
# Listener(s)
################################################################################

output "listeners" {
  description = "Map of listeners created and their associated attributes"
  value       = module.global_accelerator.listeners
}

################################################################################
# Endpoing Group(s)
################################################################################

output "endpoint_groups" {
  description = "Map of endpoints created and their associated attributes"
  value       = module.global_accelerator.endpoint_groups
}
