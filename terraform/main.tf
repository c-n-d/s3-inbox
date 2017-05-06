# Terraform configuation for s3-inbox. Configures:
#
# 1. A public S3 bucket that allows unauthenicated object puts.
# 2. A private S3 bucket where objects are moved after being reviewed.
# 3. SNS topic that receives notifications when objects are created in
#    the public bucket.
# 4. S3 bucket notification between the public bucket and SNS topic for object creation.

# TODOs:
#
# 1. Pending resolution of https://github.com/hashicorp/terraform/issues/12719
#    Move to loading policies from template files.
#    https://www.terraform.io/docs/providers/template/index.html

provider "aws" {
  region = "us-east-1"
}

# Public S3 bucket - objects can be put freely 
resource "aws_s3_bucket" "public_upload" {
  bucket = "${var.public_bucket}"
  acl    = "private"
  policy = <<POLICY
{
  "Id": "Policy123456789",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt123456789",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.public_bucket}",
        "arn:aws:s3:::${var.public_bucket}/*"
      ],
      "Principal": {"AWS":"*"}
    }
  ]
}
POLICY
}

# Private S3 bucket - publicly put objects are moved here after the lambda runs
resource "aws_s3_bucket" "private_storage" {
  bucket = "${var.private_bucket}"
  acl    = "private"
}

# SNS topic that is notified when objects are created in the public bucket
resource "aws_sns_topic" "you_got_mail_topic" {
  name = "${var.sns_topic}"
  policy = <<POLICY
{
  "Id": "Policy123456789",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt123456789",
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:sns:*:*:${var.sns_topic}",
      "Principal": {"AWS":"*"},
      "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.public_upload.arn}"}
        }
    }
  ]
}
POLICY
}

# Connect the public S3 bucket with the SNS topic using a S3 bucket notification
resource "aws_s3_bucket_notification" "public_bucket_notification" {
  bucket = "${aws_s3_bucket.public_upload.bucket}"

  topic {
    topic_arn = "${aws_sns_topic.you_got_mail_topic.arn}"
    events    = ["s3:ObjectCreated:*"]
  }
}
