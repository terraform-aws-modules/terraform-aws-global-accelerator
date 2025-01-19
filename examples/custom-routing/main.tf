provider "aws" {
  region = local.region
}

provider "aws" {
  region = local.secondary_region
  alias  = "region2"
}

locals {
  region           = "us-east-1"
  secondary_region = "us-west-2"
  name             = "ex-${replace(basename(path.cwd), "_", "-")}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-global-accelerator"
  }
}

data "aws_caller_identity" "current" {}

################################################################################
# Global Accelerator Module
################################################################################

module "global_accelerator_disabled" {
  source = "../../modules/custom-routing"

  create = false
}

module "global_accelerator" {
  source = "../../modules/custom-routing"

  name = local.name

  flow_logs_enabled   = true
  flow_logs_s3_bucket = module.s3_log_bucket.s3_bucket_id
  flow_logs_s3_prefix = local.name

  # Listeners
  listeners = {
    listener_1 = {
      endpoint_group = {
        one = {
          endpoint_group_region = "us-west-2"
          destination_configuration = [
            {
              from_port = 80
              protocols = ["TCP"]
              to_port   = 81
            },
            {
              from_port = 443
              protocols = ["TCP"]
              to_port   = 443
            }
          ]

          endpoint_configuration = [for subnet in module.secondary_vpc.public_subnets : { endpoint_id = subnet }]
        }
        two = {
          destination_configuration = [
            {
              from_port = 8080
              protocols = ["TCP"]
              to_port   = 8081
            },
            {
              from_port = 8443
              protocols = ["TCP"]
              to_port   = 8443
            }
          ]

          endpoint_configuration = [for subnet in module.vpc.private_subnets : { endpoint_id = subnet }]
        }
      }


      port_ranges = [
        {
          from_port = 80
          to_port   = 200
        },
        {
          from_port = 8081
          to_port   = 9091
        }
      ]
    }

    listener_2 = {

      endpoint_group = {
        my_group = {
          destination_configuration = [
            {
              from_port = 8080
              protocols = ["TCP"]
              to_port   = 8081
            },
            {
              from_port = 8091
              protocols = ["TCP"]
              to_port   = 8091
            }
          ]

          endpoint_configuration = [for subnet in module.vpc.private_subnets : { endpoint_id = subnet }]
        }
      }

      port_ranges = [
        {
          from_port = 201
          to_port   = 300
        },
        {
          from_port = 301
          to_port   = 400
        }
      ]
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

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = "10.99.0.0/18"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets  = ["10.99.0.0/28", "10.99.1.0/28", "10.99.2.0/28"]
  private_subnets = ["10.99.3.0/28", "10.99.4.0/28", "10.99.5.0/28"]

  tags = local.tags
}

module "secondary_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = "10.98.0.0/18"

  azs             = ["${local.secondary_region}a", "${local.secondary_region}b", "${local.secondary_region}c"]
  public_subnets  = ["10.98.0.0/28", "10.98.1.0/28", "10.98.2.0/28"]
  private_subnets = ["10.98.3.0/28", "10.98.4.0/28", "10.98.5.0/28"]

  tags = local.tags

  providers = {
    aws = aws.region2
  }
}

module "s3_log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.name}-flowlogs-${data.aws_caller_identity.current.account_id}-${local.region}"

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
