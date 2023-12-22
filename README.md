# AWS Global Accelerator Terraform module

Terraform module which creates AWS Global Accelerator resources.

## Usage

See [`examples`](https://github.com/terraform-aws-modules/terraform-aws-global-accelerator/tree/master/examples) directory for working examples to reference:

```hcl
module "global_accelerator" {
  source = "terraform-aws-modules/global-accelerator/aws"

  name = "example"

  flow_logs_enabled   = true
  flow_logs_s3_bucket = "example-global-accelerator-flow-logs"
  flow_logs_s3_prefix = "example"

  listeners = {
    listener_1 = {
      client_affinity = "SOURCE_IP"

      endpoint_group = {
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

## Examples

Examples codified under the [`examples`](https://github.com/terraform-aws-modules/terraform-aws-global-accelerator/tree/master/examples) are intended to give users references for how to use the module(s) as well as testing/validating changes to the source code of the module. If contributing to the project, please be sure to make any appropriate updates to the relevant examples to allow maintainers to test your changes and to keep the examples up to date for users. Thank you!

- [Complete](https://github.com/terraform-aws-modules/terraform-aws-global-accelerator/tree/master/examples/complete)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.61 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_globalaccelerator_accelerator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_accelerator) | resource |
| [aws_globalaccelerator_endpoint_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_endpoint_group) | resource |
| [aws_globalaccelerator_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_listener) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created (affects nearly all resources) | `bool` | `true` | no |
| <a name="input_create_listeners"></a> [create\_listeners](#input\_create\_listeners) | Controls if listeners should be created (affects only listeners) | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Indicates whether the accelerator is enabled. Defaults to `true`. Valid values: `true`, `false` | `bool` | `true` | no |
| <a name="input_endpoint_groups_timeouts"></a> [endpoint\_groups\_timeouts](#input\_endpoint\_groups\_timeouts) | Create, update, and delete timeout configurations for the endpoint groups | `map(string)` | `{}` | no |
| <a name="input_flow_logs_enabled"></a> [flow\_logs\_enabled](#input\_flow\_logs\_enabled) | Indicates whether flow logs are enabled. Defaults to `false` | `bool` | `false` | no |
| <a name="input_flow_logs_s3_bucket"></a> [flow\_logs\_s3\_bucket](#input\_flow\_logs\_s3\_bucket) | The name of the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true` | `string` | `null` | no |
| <a name="input_flow_logs_s3_prefix"></a> [flow\_logs\_s3\_prefix](#input\_flow\_logs\_s3\_prefix) | The prefix for the location in the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true` | `string` | `null` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | The value for the address type. Defaults to `IPV4`. Valid values: `IPV4`, `DUAL_STACK` | `string` | `"IPV4"` | no |
| <a name="input_ip_addresses"></a> [ip\_addresses](#input\_ip\_addresses) | The IP addresses to use for BYOIP accelerators. If not specified, the service assigns IP addresses. Valid values: 1 or 2 IPv4 addresses | `list(string)` | `[]` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | A map of listener defintions to create | `any` | `{}` | no |
| <a name="input_listeners_timeouts"></a> [listeners\_timeouts](#input\_listeners\_timeouts) | Create, update, and delete timeout configurations for the listeners | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the accelerator | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name of the accelerator |
| <a name="output_dual_stack_dns_name"></a> [dual\_stack\_dns\_name](#output\_dual\_stack\_dns\_name) | The DNS name that Global Accelerator creates that points to a dual-stack accelerator's four static IP addresses: two IPv4 addresses and two IPv6 addresses |
| <a name="output_endpoint_groups"></a> [endpoint\_groups](#output\_endpoint\_groups) | Map of endpoints created and their associated attributes |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The Global Accelerator Route 53 zone ID that can be used to route an Alias Resource Record Set to the Global Accelerator |
| <a name="output_id"></a> [id](#output\_id) | The Amazon Resource Name (ARN) of the accelerator |
| <a name="output_ip_sets"></a> [ip\_sets](#output\_ip\_sets) | IP address set associated with the accelerator |
| <a name="output_listeners"></a> [listeners](#output\_listeners) | Map of listeners created and their associated attributes |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/terraform-aws-modules/terraform-aws-global-accelerator/blob/master/LICENSE).
