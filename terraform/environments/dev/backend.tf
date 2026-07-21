################################################################################
# BACKEND S3 + DYNAMODB - Configuration automatique
################################################################################

# backend.tf (avec valeur fixe)
terraform {
  backend "s3" {
    bucket         = "petclinic-tfstate-2026"
    key            = "petclinic/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "petclinic-tf-locks"
  }
}