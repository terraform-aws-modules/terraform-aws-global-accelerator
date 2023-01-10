provider "aws" {
  region = "eu-west-1"
  alias  = "eu"
}

provider "aws" {
  region = "us-west-1"
  alias  = "us"
}

locals {
  name = "ga-${replace(basename(path.cwd), "_", "-")}"
  # name = "global-acclerator-ex-${replace(basename(path.cwd), "_", "-")}" Over 32 characters

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-global-accelerator"
  }
}

################################################################################
# Supporting Resources
################################################################################

module "vpc_eu" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  providers = {
    aws = aws.eu
  }

  name = local.name
  cidr = "10.99.0.0/18"

  azs            = data.aws_availability_zones.eu.names
  public_subnets = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]

  tags = local.tags
}
module "alb_eu" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 7.0"

  providers = {
    aws = aws.eu
  }

  name               = local.name
  load_balancer_type = "application"

  vpc_id          = module.vpc_eu.vpc_id
  subnets         = module.vpc_eu.public_subnets
  security_groups = [module.vpc_eu.default_security_group_id]

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

module "vpc_us" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  providers = {
    aws = aws.us
  }

  name = local.name
  cidr = "10.99.0.0/18"

  azs            = data.aws_availability_zones.us.names
  public_subnets = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]

  tags = local.tags
}
module "alb_us" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 7.0"

  providers = {
    aws = aws.us
  }

  name               = local.name
  load_balancer_type = "application"

  vpc_id          = module.vpc_us.vpc_id
  subnets         = module.vpc_us.public_subnets
  security_groups = [module.vpc_us.default_security_group_id]

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


################################################################################
# Global Accelerator Module
################################################################################

module "global_accelerator" {
  source = "../.."

  name = local.name

  # Listeners
  listeners = {
    listener_1 = {
      client_affinity = "SOURCE_IP"

      endpoint_groups = {
        eu = {
          endpoint_group_region         = "eu-west-1"
          health_check_port             = 80
          health_check_protocol         = "HTTP"
          health_check_path             = "/"
          health_check_interval_seconds = 10
          health_check_timeout_seconds  = 5
          threshold_count               = 2
          # unhealthy_threshold_count     = 2
          traffic_dial_percentage = 100

          # Health checks will show as unhealthy in this example because there
          # are obviously no healthy instances in the target group
          endpoint_configuration = [{
            client_ip_preservation_enabled = true
            endpoint_id                    = module.alb_eu.lb_arn
          }]

          port_override = [{
            endpoint_port = 82
            listener_port = 80
          }]
        }
        us = {
          endpoint_group_region         = "us-west-1"
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
            endpoint_id                    = module.alb_us.lb_arn
          }]

          port_override = [{
            endpoint_port = 82
            listener_port = 80
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

data "aws_availability_zones" "eu" {
  provider = aws.eu
  state    = "available"
}
data "aws_availability_zones" "us" {
  provider = aws.us
  state    = "available"
}
