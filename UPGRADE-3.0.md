# Upgrade from v2.x to v3.x

If you have any questions regarding this upgrade process, please consult the `examples` directory:

- [Complete](examples/complete): A standard complete example of Global Accelerator
- [Custom Routing](examples/custom-routing): A custom routing example of Global Accelerator


If you find a bug, please open an issue with supporting configuration to reproduce.

## Changes

- Added `endpoint_configuration.attachment_arn` to `aws_globalaccelerator_endpoint_group`
- Minimum version of AWS provider increased to v5.0 to support features added
- Changed `endpoint_group` to `endpoint_groups` to facilitate multiple endpoint groups per listener

## List of backwards incompatible changes

- Added support for adding multiple endpoint groups per listener which requires updating `endpoint_group` to `endpoint_groups` and passing a nested map to `endpoint_groups` containing a group name key

### Variable and output changes

1. Removed variables:

   - None

2. Renamed variables:

   - None

3. Added variables:

   - None

4. Removed outputs:

   - None

5. Renamed outputs:

   - None

6. Added outputs:

   - Accelerator `arn`

## Upgrade Migrations

### Before 2.x Example

```hcl
module "global_accelerator" {
  source = "terraform-aws-modules/global-accelerator/aws"
  version = "~> 2.0"

  name = "example"

  flow_logs_enabled   = true
  flow_logs_s3_bucket = "example-global-accelerator-flow-logs"
  flow_logs_s3_prefix = "example"

  listeners = {
    listener_1 = {
      client_affinity = "SOURCE_IP"

      endpoint_groups = {
        health_check_port             = 80
        health_check_protocol         = "HTTP"
        health_check_path             = "/"
        health_check_interval_seconds = 10
        health_check_timeout_seconds  = 5
        healthy_threshold_count       = 2
        unhealthy_threshold_count     = 2
        traffic_dial_percentage       = 100

        endpoint_configuration = [{
          client_ip_preservation_enabled = true
          endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/blue/1234567890123456"
          weight                         = 50
        }, {
          client_ip_preservation_enabled = false
          endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/green/1234567890123456"
          weight                         = 50
        }]

        port_override = [{
          endpoint_port = 82
          listener_port = 80
        }, {
          endpoint_port = 8082
          listener_port = 8080
        }, {
          endpoint_port = 8083
          listener_port = 8081
        }]
      }

      port_ranges = [
        {
          from_port = 80
          to_port   = 81
        },
        {
          from_port = 8080
          to_port   = 8081
        }
      ]
      protocol = "TCP"
    }

    listener_2 = {
      port_ranges = [
        {
          from_port = 443
          to_port   = 443
        },
        {
          from_port = 8443
          to_port   = 8443
        }
      ]
      protocol = "TCP"
    }

    listener_3 = {
      port_ranges = [
        {
          from_port = 53
          to_port   = 53
        }
      ]
      protocol = "UDP"
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### After 3.x Example

```hcl
module "global_accelerator" {
  source = "terraform-aws-modules/global-accelerator/aws"
  version = "~> 3.0"

  name = "example"

  flow_logs_enabled   = true
  flow_logs_s3_bucket = "example-global-accelerator-flow-logs"
  flow_logs_s3_prefix = "example"

  listeners = {
    listener_1 = {
      client_affinity = "SOURCE_IP"

      endpoint_groups = {
        my_group = {
          health_check_port             = 80
          health_check_protocol         = "HTTP"
          health_check_path             = "/"
          health_check_interval_seconds = 10
          health_check_timeout_seconds  = 5
          healthy_threshold_count       = 2
          unhealthy_threshold_count     = 2
          traffic_dial_percentage       = 100

          endpoint_configuration = [{
            client_ip_preservation_enabled = true
            endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/blue/1234567890123456"
            weight                         = 50
          }, {
            client_ip_preservation_enabled = false
            endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/green/1234567890123456"
            weight                         = 50
          }]

          port_override = [{
            endpoint_port = 82
            listener_port = 80
          }, {
            endpoint_port = 8082
            listener_port = 8080
          }, {
            endpoint_port = 8083
            listener_port = 8081
          }]
        }
      }

      port_ranges = [
        {
          from_port = 80
          to_port   = 81
        },
        {
          from_port = 8080
          to_port   = 8081
        }
      ]
      protocol = "TCP"
    }

    listener_2 = {
      port_ranges = [
        {
          from_port = 443
          to_port   = 443
        },
        {
          from_port = 8443
          to_port   = 8443
        }
      ]
      protocol = "TCP"
    }

    listener_3 = {
      port_ranges = [
        {
          from_port = 53
          to_port   = 53
        }
      ]
      protocol = "UDP"
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### State Changes

To migrate from the `v2.x` version to `v3.x` version example shown above, the following state move commands can be performed to maintain the current resources without modification:

```bash
terraform state mv 'module.global_accelerator.aws_globalaccelerator_endpoint_group.this["<user_defined_listener_key_name>"]' 'module.global_accelerator.aws_globalaccelerator_endpoint_group.this["<user_defined_listener_key_name>:<user_defined_group_key_name>"]'
```

For example, if you previously had a configuration such as (truncated for brevity):

```hcl
module "global_accelerator" {
  source = "terraform-aws-modules/global-accelerator/aws"
  version = "~> 2.0"

  name = "example"

  listeners = {
    listener_1 = {

      endpoint_groups = {
        endpoint_configuration = [
          {
            client_ip_preservation_enabled = true
            endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/blue/1234567890123456"
            weight                         = 50
          }, {
            client_ip_preservation_enabled = false
            endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/green/1234567890123456"
            weight                         = 50
          }
        ]

        port_override = [
          {
            endpoint_port = 82
            listener_port = 80
          }, {
            endpoint_port = 8082
            listener_port = 8080
          }, {
            endpoint_port = 8083
            listener_port = 8081
          }
        ]
      }
    }
  }
}
```

After updating the configuration to the latest 3.x changes:

```hcl
module "global_accelerator" {
  source = "terraform-aws-modules/global-accelerator/aws"
  version = "~> 3.0"

  name = "example"

  listeners = {
    listener_1 = {

      endpoint_groups = {
        group_1 = {
          endpoint_configuration = [
            {
              client_ip_preservation_enabled = true
              endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/blue/1234567890123456"
              weight                         = 50
            }, {
              client_ip_preservation_enabled = false
              endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/green/1234567890123456"
              weight                         = 50
            }
          ]

          port_override = [
            {
              endpoint_port = 82
              listener_port = 80
            }, {
              endpoint_port = 8082
              listener_port = 8080
            }, {
              endpoint_port = 8083
              listener_port = 8081
            }
          ]
        }
      }
    }
  }
}
```

The associated Terraform state move commands would be:

```bash
terraform state mv 'module.global_accelerator.aws_globalaccelerator_endpoint_group.this["listener_1"]' 'module.global_accelerator.aws_globalaccelerator_endpoint_group.this["listener_1:group_1"]'
```
