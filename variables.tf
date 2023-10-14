variable "aws_region" {
  type        = string
  default     = ""
  description = "AWS region for the created resources.  Will default to the session region."
}

variable "s3_bucket_name" {
  type        = string
  default     = null
  description = "Name for the S3 bucket created to store Terraform state."
}

variable "s3_key_prefix" {
  type        = string
  default     = null
  description = "Key name for the Terraform state objects in the S3 bucket."
}

variable "dynamo_table_name" {
  type        = string
  default     = "terraform-lock"
  description = "Name for the DynamoDB table created to lock Terraform state."
}

variable "iam_policy_name" {
  type        = string
  default     = "Terraform-S3-Backend"
  description = "Name for the IAM policy enabling access to the backend resource."
}

variable "parameter_prefix" {
  type    = string
  default = "terraform-state"
}
