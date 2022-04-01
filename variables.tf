variable "environemnt_code" {
  description = "What color code?"
  type        = string
}

variable "ami_base" {
  description = "AWS AMIs for base images"
  default = {
    "centos-7"     = "ami-2af1ca3d"
    "ubuntu-14.04" = "ami-d79487c0"
  }
}

variable "route53_zone" {
  description = "Route53 zone used for DNS records"
  default = {
    id   = "Z1ME2RCUVBYEW2"
    name = "tuxlabs.com"
  }
}

