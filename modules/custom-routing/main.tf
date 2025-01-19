################################################################################
# Custom Routing Accelerator
################################################################################

resource "aws_globalaccelerator_custom_routing_accelerator" "this" {
  count = var.create ? 1 : 0

  name            = var.name
  ip_address_type = var.ip_address_type
  ip_addresses    = var.ip_addresses
  enabled         = var.enabled

  dynamic "attributes" {
    for_each = var.flow_logs_enabled ? [1] : []
    content {
      flow_logs_enabled   = var.flow_logs_enabled
      flow_logs_s3_bucket = var.flow_logs_s3_bucket
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = var.tags
}

################################################################################
# Custom Routing Listener(s)
################################################################################

resource "aws_globalaccelerator_custom_routing_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if var.create && var.create_listeners }

  accelerator_arn = aws_globalaccelerator_custom_routing_accelerator.this[0].id

  dynamic "port_range" {
    for_each = try(each.value.port_ranges, null) != null ? each.value.port_ranges : []
    content {
      from_port = try(port_range.value.from_port, null)
      to_port   = try(port_range.value.to_port, null)
    }
  }

  timeouts {
    create = try(var.listeners_timeouts.create, null)
    update = try(var.listeners_timeouts.update, null)
    delete = try(var.listeners_timeouts.delete, null)
  }
}

################################################################################
# Custom Routing Endpoint Group(s)
################################################################################
locals {
  endpoint_groups = flatten([
    for listener, listener_configs in var.listeners : [
      for endpoint_group, endpoint_group_configs in listener_configs.endpoint_group : {
        listener               = listener
        endpoint_group         = endpoint_group
        endpoint_group_configs = endpoint_group_configs
      }
    ] if length(lookup(listener_configs, "endpoint_group", {})) > 0
  ])
}

resource "aws_globalaccelerator_custom_routing_endpoint_group" "this" {
  for_each = { for k, v in local.endpoint_groups : "${v.listener}:${v.endpoint_group}" => v if var.create && var.create_listeners }

  listener_arn          = aws_globalaccelerator_custom_routing_listener.this[each.value.listener].id
  endpoint_group_region = try(each.value.endpoint_group_configs.endpoint_group_region, null)

  dynamic "destination_configuration" {
    for_each = [for e in try(each.value.endpoint_group_configs.destination_configuration, []) : e]
    content {
      from_port = destination_configuration.value.from_port
      protocols = destination_configuration.value.protocols
      to_port   = destination_configuration.value.to_port
    }
  }

  dynamic "endpoint_configuration" {
    for_each = [for e in try(each.value.endpoint_group_configs.endpoint_configuration, []) : e if can(e.endpoint_id)]
    content {
      endpoint_id = endpoint_configuration.value.endpoint_id
    }
  }

  timeouts {
    create = try(var.endpoint_groups_timeouts.create, null)
    delete = try(var.endpoint_groups_timeouts.delete, null)
  }
}
