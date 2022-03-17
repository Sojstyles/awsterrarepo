variable "environemnt_code" {
  description = "green"
  type        = string
}

variable "name" {
  description = "Name to be used on securitygroup created"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "A mapping of tags to assign to the devices created by the instance at launch time"
  type        = map(string)
  default     = {}
}
