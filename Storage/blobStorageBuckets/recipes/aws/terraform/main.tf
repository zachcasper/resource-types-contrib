terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

variable "context" {
  description = "Radius-provided object containing information about the resource calling the Recipe. For more information visit https://docs.radapp.io/reference/context-schema/"
  type        = any
}


# Generate a unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  # Extract properties from context
  storage_class      = try(var.context.resource.properties.class, "hot")
  access_application = try(var.context.resource.properties.accessControl.application, "ReadWrite")
  access_group       = try(var.context.resource.properties.accessControl.group, "ReadWrite")
  access_public      = try(var.context.resource.properties.accessControl.public, "None")
  
  # Map storage class to S3 storage class
  s3_storage_class = local.storage_class == "hot" ? "STANDARD" : (
    local.storage_class == "cool" ? "STANDARD_IA" : "GLACIER"
  )
  
  # Generate unique bucket name
  bucket_name = "${var.context.application.name}-${var.context.resource.name}-${random_string.bucket_suffix.result}"
  
  # Determine public access settings
  block_public_access = local.access_public == "None"
}

# S3 Bucket
resource "aws_s3_bucket" "blob_storage" {
  bucket = local.bucket_name
  
  tags = {
    Name                = var.context.resource.name
    Application         = var.context.application != null ? var.context.application.name : ""
    Environment         = var.context.environment.name
    "radapp.io/resource" = var.context.resource.name
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "blob_storage" {
  bucket = aws_s3_bucket.blob_storage.id
  
  block_public_acls       = local.block_public_access
  block_public_policy     = local.block_public_access
  ignore_public_acls      = local.block_public_access
  restrict_public_buckets = local.block_public_access
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "blob_storage" {
  bucket = aws_s3_bucket.blob_storage.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Lifecycle Configuration for storage class transitions
resource "aws_s3_bucket_lifecycle_configuration" "blob_storage" {
  count  = local.storage_class != "hot" ? 1 : 0
  bucket = aws_s3_bucket.blob_storage.id
  
  rule {
    id     = "transition-to-${local.s3_storage_class}"
    status = "Enabled"
    
    transition {
      days          = 0
      storage_class = local.s3_storage_class
    }
  }
}

# IAM User for S3 access
resource "aws_iam_user" "s3_user" {
  name = "${local.bucket_name}-user"
  
  tags = {
    Application = var.context.application != null ? var.context.application.name : ""
    Bucket      = local.bucket_name
  }
}

# IAM Access Key for the user
resource "aws_iam_access_key" "s3_user" {
  user = aws_iam_user.s3_user.name
}

# IAM Policy for bucket access
resource "aws_iam_user_policy" "s3_access" {
  name = "${local.bucket_name}-policy"
  user = aws_iam_user.s3_user.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = local.access_application == "ReadWrite" ? [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ] : local.access_application == "Read" ? [
          "s3:GetObject",
          "s3:ListBucket"
        ] : []
        Resource = [
          aws_s3_bucket.blob_storage.arn,
          "${aws_s3_bucket.blob_storage.arn}/*"
        ]
      }
    ]
  })
}

# Bucket policy for public read access if configured
resource "aws_s3_bucket_policy" "public_read" {
  count  = local.access_public == "Read" ? 1 : 0
  bucket = aws_s3_bucket.blob_storage.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.blob_storage.arn}/*"
      }
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.blob_storage]
}

# Output the result matching the resource type schema
output "result" {
  value = {
    values = {
      uniqueName   = aws_s3_bucket.blob_storage.id
      region       = aws_s3_bucket.blob_storage.region
      endpointUrl  = "https://s3.${aws_s3_bucket.blob_storage.region}.amazonaws.com"
    }
    secrets = {
      awsAccessKeyId     = aws_iam_access_key.s3_user.id
      awsSecretAccessKey = aws_iam_access_key.s3_user.secret
    }
    # UCP resource IDs for cleanup
    resources = []
  }
  description = "The result of the Recipe. Must match the blobStorageBuckets resource schema."
  sensitive   = true
}
