variable "public_bucket" {
  type    = "string"
  default = "s3-inbox-public"
}

variable "private_bucket" {
  type    = "string"
  default = "s3-inbox-private"
}

variable "sns_topic" {
  type    = "string"
  default = "inbox_notification_topic"
}
