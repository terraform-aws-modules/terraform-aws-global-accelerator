################################################################################
# Accelerator
################################################################################

resource "aws_globalaccelerator_accelerator" "this" {
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
# Listener(s)
################################################################################

resource "aws_globalaccelerator_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if var.create && var.create_listeners }

  accelerator_arn = aws_globalaccelerator_accelerator.this[0].id
  client_affinity = lookup(each.value, "client_affinity", null)
  protocol        = lookup(each.value, "protocol", null)

  dynamic "port_range" {
    for_each = try(each.value.port_ranges, null) != null ? each.value.port_ranges : []
    content {
      from_port = lookup(port_range.value, "from_port", null)
      to_port   = lookup(port_range.value, "to_port", null)
    }
  }

  timeouts {
    create = lookup(var.listeners_timeouts, "create", null)
    update = lookup(var.listeners_timeouts, "update", null)
    delete = lookup(var.listeners_timeouts, "delete", null)
  }
}

################################################################################
# Endpoint Group(s)
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

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = { for k, v in local.endpoint_groups : "${v.listener}:${v.endpoint_group}" => v if var.create && var.create_listeners }

  listener_arn = aws_globalaccelerator_listener.this[each.value.listener].id

  endpoint_group_region         = try(each.value.endpoint_group_configs.endpoint_group_region, null)
  health_check_interval_seconds = try(each.value.endpoint_group_configs.health_check_interval_seconds, null)
  health_check_path             = try(each.value.endpoint_group_configs.health_check_path, null)
  health_check_port             = try(each.value.endpoint_group_configs.health_check_port, null)
  health_check_protocol         = try(each.value.endpoint_group_configs.health_check_protocol, null)
  threshold_count               = try(each.value.endpoint_group_configs.threshold_count, null)
  traffic_dial_percentage       = try(each.value.endpoint_group_configs.traffic_dial_percentage, null)

  dynamic "endpoint_configuration" {
    for_each = [for e in try(each.value.endpoint_group_configs.endpoint_configuration, []) : e if can(e.endpoint_id)]
    content {
      attachment_arn                 = try(endpoint_configuration.value.attachment_arn, null)
      client_ip_preservation_enabled = try(endpoint_configuration.value.client_ip_preservation_enabled, null)
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = try(endpoint_configuration.value.weight, null)
    }
  }

  dynamic "port_override" {
    for_each = can(each.value.endpoint_group_configs.port_override) ? each.value.endpoint_group_configs.port_override : []
    content {
      endpoint_port = port_override.value.endpoint_port
      listener_port = port_override.value.listener_port
    }
  }

  timeouts {
    create = lookup(var.endpoint_groups_timeouts, "create", null)
    update = lookup(var.endpoint_groups_timeouts, "update", null)
    delete = lookup(var.endpoint_groups_timeouts, "delete", null)
  }
}
