output "web_acl_arn" {
  description = "ARN du Web ACL WAF"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_id" {
  description = "ID du Web ACL WAF"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_log_bucket" {
  description = "Bucket S3 pour les logs WAF"
  value       = aws_s3_bucket.waf_logs.id
}

output "waf_log_bucket_arn" {
  description = "ARN du bucket S3 pour les logs WAF"
  value       = aws_s3_bucket.waf_logs.arn
}

output "waf_log_group" {
  description = "Nom du groupe de logs CloudWatch pour WAF"
  value       = aws_cloudwatch_log_group.waf.name
}

output "waf_log_group_arn" {
  description = "ARN du groupe de logs CloudWatch pour WAF"
  value       = aws_cloudwatch_log_group.waf.arn
}