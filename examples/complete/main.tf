provider "aws" {
  region = local.region
}

locals {
  region = "us-east-1"
  name   = "global-acclerator-ex-${replace(basename(path.cwd), "_", "-")}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-global-accelerator"
  }
}

data "aws_caller_identity" "current" {}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = "10.99.0.0/18"

  azs            = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 7.0"

  name               = local.name
  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.vpc.default_security_group_id]

  http_tcp_listeners = [{
    port               = 80
    protocol           = "HTTP"
    target_group_index = 0
  }]

  target_groups = [{
    backend_protocol = "HTTP"
    backend_port     = 80
    target_type      = "ip"
  }]

  tags = local.tags
}

module "s3_log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.name}-flowlogs-${data.aws_caller_identity.current.account_id}-${local.region}"
  acl    = "log-delivery-write"

  # Not recommended for production, required for testing
  force_destroy = true

  # Provides the necessary policy for flow logs to be delivered
  attach_lb_log_delivery_policy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}

################################################################################
# Global Accelerator Module
################################################################################

module "global_accelerator_disabled" {
  source = "../.."

  create = false
}

module "global_accelerator" {
  source = "../.."

  name = local.name

  flow_logs_enabled   = true
  flow_logs_s3_bucket = module.s3_log_bucket.s3_bucket_id
  flow_logs_s3_prefix = local.name

  # Listeners
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

        # Health checks will show as unhealthy in this example because there
        # are obviously no healthy instances in the target group
        endpoint_configuration = [{
          client_ip_preservation_enabled = true
          endpoint_id                    = module.alb.lb_arn
          weight                         = 50
          }, {
          client_ip_preservation_enabled = false
          endpoint_id                    = module.alb.lb_arn
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

  listeners_timeouts = {
    create = "35m"
    update = "35m"
    delete = "35m"
  }

  endpoint_groups_timeouts = {
    create = "35m"
    update = "35m"
    delete = "35m"
  }

  tags = local.tags
}
