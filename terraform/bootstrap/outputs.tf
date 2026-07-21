output "bootstrap_instructions" {
  value = <<-EOT
    ========================================
    ✅ BACKEND TERRAFORM CRÉÉ AVEC SUCCÈS !
    ========================================
    
    Bucket S3   : ${aws_s3_bucket.terraform_state.bucket}
    Table DynamoDB : ${aws_dynamodb_table.terraform_locks.name}
    
    Vous pouvez maintenant exécuter :
    cd ../environments/dev
    terraform init
    ========================================
  EOT
}