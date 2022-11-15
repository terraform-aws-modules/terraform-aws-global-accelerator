locals {
  listener_endpoints = flatten([for lk, lv in var.listeners : [
    for ek, ev in lv.endpoint_groups : {
      listerner_name = lk
      endpoint_group = ek

      endpoint_group_region         = ev.endpoint_group_region
      health_check_port             = ev.health_check_port
      health_check_protocol         = ev.health_check_protocol
      health_check_path             = ev.health_check_path
      health_check_interval_seconds = ev.health_check_interval_seconds
      healthy_threshold_count       = ev.healthy_threshold_count
      traffic_dial_percentage       = ev.traffic_dial_percentage

      endpoint_configuration = ev.endpoint_configuration

      port_override = ev.port_override
    }
    ]
  ])
}

################################################################################
# Accelerator
################################################################################

resource "aws_globalaccelerator_accelerator" "this" {
  count = var.create ? 1 : 0

  name            = var.name
  ip_address_type = var.ip_address_type
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
# Endpoing Group(s)
################################################################################

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = { for v in local.listener_endpoints : "${v.listerner_name}-${v.endpoint_group}" => v if var.create && var.create_listeners }

  listener_arn = aws_globalaccelerator_listener.this[each.value.listerner_name].id

  endpoint_group_region         = try(each.value.endpoint_group_region, null)
  health_check_interval_seconds = try(each.value.health_check_interval_seconds, null)
  health_check_path             = try(each.value.health_check_path, null)
  health_check_port             = try(each.value.health_check_port, null)
  health_check_protocol         = try(each.value.health_check_protocol, null)
  threshold_count               = try(each.value.threshold_count, null)
  traffic_dial_percentage       = try(each.value.traffic_dial_percentage, null)

  dynamic "endpoint_configuration" {
    for_each = [for e in try(each.value.endpoint_configuration, []) : e if can(e.endpoint_id)]
    content {
      client_ip_preservation_enabled = try(endpoint_configuration.value.client_ip_preservation_enabled, null)
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = try(endpoint_configuration.value.weight, null)
    }
  }

  dynamic "port_override" {
    for_each = can(each.value.port_override) ? each.value.port_override : []
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
