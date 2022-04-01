variable "environemnt_code" {
  description = "What color code?"
  type        = string
}

variable "route53_zone" {
  description = "Route53 zone used for DNS records"
  default = {
    id   = "Z1ME2RCUVBYEW2"
    name = "tuxlabs.com"
  }
}

