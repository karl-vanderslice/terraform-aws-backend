data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = can(var.s3_bucket_name) ? var.s3_bucket_name : null

  tags = {
    Name        = "Terraform S3 Backend - State"
    application = "Terraform S3 Backend"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock_table" {
  name     = var.dynamo_table_name
  hash_key = "LockID"

  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform S3 Backend - Locking"
    application = "Terraform S3 Backend"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_policy" "terraform_s3_backend_policy" {
  name        = var.iam_policy_name
  description = "Terraform S3 backend access."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Bucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.terraform_state_bucket.arn
      },
      {
        Sid    = "StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = var.s3_key_prefix != null ? "${aws_s3_bucket.terraform_state_bucket.arn}/${var.s3_key_prefix}/*" : "${aws_s3_bucket.terraform_state_bucket.arn}/*"
      },
      {
        Sid    = "Locking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_lock_table.arn
      },
      {
        Sid    = "Parameters"
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters",
          "ssm:GetParameter",
          "ssm:GetParameterHistory",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.parameter_prefix}/*"
      }
    ]
  })
}
