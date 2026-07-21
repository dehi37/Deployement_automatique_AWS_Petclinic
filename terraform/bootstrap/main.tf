################################################################################
# BOOTSTRAP - Création automatique du backend S3 + DynamoDB
# Exécutez ceci UNE SEULE FOIS, il créera tout automatiquement !
################################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── 1. Bucket S3 pour l'état Terraform ──────────────────────────────────────
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  force_destroy = true  # ✅ Permet de supprimer le bucket même s'il contient des objets

  tags = {
    Name        = var.bucket_name
    Purpose     = "Terraform Remote State"
    ManagedBy   = "Terraform-Bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ❌ SUPPRIMÉ : aws_s3_bucket_policy (causait l'erreur MalformedPolicy)
# ❌ SUPPRIMÉ : data.aws_iam_policy_document.terraform_state

# ── 2. Table DynamoDB pour le verrouillage ──────────────────────────────────
resource "aws_dynamodb_table" "terraform_locks" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # ✅ Force la suppression même avec des données
  deletion_protection_enabled = false

  tags = {
    Name      = var.dynamodb_table_name
    Purpose   = "Terraform State Lock"
    ManagedBy = "Terraform-Bootstrap"
  }
}

# ── Outputs ────────────────────────────────────────────────────────────────────
output "bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.terraform_locks.arn
}

output "message" {
  value = "✅ Backend Terraform créé avec succès !"
}