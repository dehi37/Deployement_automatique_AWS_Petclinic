variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "petclinic-tfstate-2026" # ⚠️ Changez ce nom pour qu'il soit UNIQUE
}

variable "dynamodb_table_name" {
  type    = string
  default = "petclinic-tf-locks"
}