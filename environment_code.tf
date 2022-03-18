variable "environemnt_code" {
  description = "What color code?"
  type        = string
}

variable "instance_tags" {
  type = object({
    Name = string
    foo  = number
  })
}
