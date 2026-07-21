output "cloudfront_domain_name" {
  description = "URL publique CloudFront"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID de la distribution CloudFront"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribution CloudFront"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_cache_policy_id" {
  description = "ID de la politique de cache"
  value       = aws_cloudfront_cache_policy.main.id
}

output "cloudfront_log_bucket" {
  description = "Bucket S3 pour les logs CloudFront"
  value       = try(aws_s3_bucket.logs[0].id, null)
}

output "cloudfront_function_arn" {
  description = "ARN de la fonction CloudFront"
  value       = aws_cloudfront_function.security_headers.arn
}