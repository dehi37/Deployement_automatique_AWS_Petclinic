################################################################################
# Module WAF – Web Application Firewall (Version avec S3)
################################################################################

# ── WAF ACL pour ALB ──────────────────────────────────────────────────────────
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.name_prefix}-waf"
  description = "WAF ACL pour proteger l ALB Spring PetClinic"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # ── Règle 1 : AWS Managed - Core Rule Set ────────────────────────────────
  rule {
    name     = "AWSManagedCRS"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedCRS"
      sampled_requests_enabled   = true
    }
  }

  # ── Règle 2 : AWS Managed - SQL Injection ────────────────────────────────
  rule {
    name     = "AWSManagedSQL"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedSQL"
      sampled_requests_enabled   = true
    }
  }

  # ── Règle 3 : Rate limiting ───────────────────────────────────────────────
  dynamic "rule" {
    for_each = var.enable_rate_limiting ? [1] : []

    content {
      name     = "RateLimit"
      priority = 3

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimit"
        sampled_requests_enabled   = true
      }
    }
  }

  # ── Règle 4 : Filtrage géographique ──────────────────────────────────────


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-WAFMetric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.name_prefix}-waf"
  }
}

# ── Association WAF avec ALB ────────────────────────────────────────────────
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# ── Bucket S3 pour les logs WAF ─────────────────────────────────────────────
resource "aws_s3_bucket" "waf_logs" {
  bucket        = "${var.name_prefix}-waf-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.name_prefix}-waf-logs"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket                  = aws_s3_bucket.waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  policy = data.aws_iam_policy_document.waf_logs.json
}

data "aws_iam_policy_document" "waf_logs" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["wafv2.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.waf_logs.arn}/*"]
  }
}

# ── Logging WAF (S3 + CloudWatch) ──────────────────────────────────────────
# Dans modules/waf/main.tf
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_waf_logging ? 1 : 0  # Ajoutez cette condition
  
  log_destination_configs = [
    aws_s3_bucket.waf_logs.arn,
    aws_cloudwatch_log_group.waf.arn
  ]
  resource_arn = aws_wafv2_web_acl.main.arn

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

# ── CloudWatch Logs pour WAF ────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/waf/${var.name_prefix}"
  retention_in_days = 30
}

# ── Dashboard WAF ────────────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "waf" {
  dashboard_name = "${var.name_prefix}-waf-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.main.arn, "Rule", "ALL"],
            ["AWS/WAFV2", "AllowedRequests", "WebACL", aws_wafv2_web_acl.main.arn, "Rule", "ALL"],
            ["AWS/WAFV2", "CountedRequests", "WebACL", aws_wafv2_web_acl.main.arn, "Rule", "ALL"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "WAF - Requêtes Bloquées / Autorisées / Comptées"
          view   = "timeSeries"
          stacked = true
        }
      }
    ]
  })
}