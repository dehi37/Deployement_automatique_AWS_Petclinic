################################################################################
# Module CloudFront – CDN global pour sécuriser et accélérer l'application
# Protection DDoS, HTTPS, caching, géo-restriction, headers de sécurité
################################################################################


# ── CloudFront Distribution ──────────────────────────────────────────────────
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""

  # ── Aliases (nom de domaine personnalisé) ──────────────────────────────
  aliases = var.domain_name != null ? [var.domain_name] : []

  # ── Origin : ALB ─────────────────────────────────────────────────────────
  origin {
    domain_name              = var.alb_dns_name
    origin_id                = "ALB_${var.name_prefix}"
    #origin_access_control_id = aws_cloudfront_origin_access_control.main.id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }
  }

  # ── Cache behavior ────────────────────────────────────────────────────────
  default_cache_behavior {
    target_origin_id       = "ALB_${var.name_prefix}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Cache policy
    cache_policy_id = aws_cloudfront_cache_policy.main.id

    # Origin request policy
    origin_request_policy_id = aws_cloudfront_origin_request_policy.main.id

    # Response headers policy
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
  }

  # ── Custom error responses ───────────────────────────────────────────────
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_page_path    = custom_error_response.value.response_page_path
      response_code         = custom_error_response.value.response_code
      error_caching_min_ttl = try(custom_error_response.value.error_caching_min_ttl, 300)
    }
  }

  # ── Restrictions ──────────────────────────────────────────────────────────
  restrictions {
    geo_restriction {
      restriction_type = var.enable_geo_restriction ? "whitelist" : "none"
      locations        = var.enable_geo_restriction ? var.geo_restriction_locations : []
    }
  }

  # ── SSL/TLS ───────────────────────────────────────────────────────────────
  viewer_certificate {
    cloudfront_default_certificate = true # var.certificate_arn != null && var.certificate_arn != "" ? false : true
    #acm_certificate_arn            = var.certificate_arn != null && var.certificate_arn != "" ? var.certificate_arn : null
    # minimum_protocol_version       = "TLSv1.2_2021"
    # ssl_support_method             = var.certificate_arn != null && var.certificate_arn != "" ? "sni-only" : null
  }

  # ── WAF Association ────────────────────────────────────────────────────────
  web_acl_id = var.web_acl_arn

  # ── Logging ────────────────────────────────────────────────────────────────
  dynamic "logging_config" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      include_cookies = true
      bucket          = var.log_bucket_name != null ? "${var.log_bucket_name}.s3.amazonaws.com" : "${aws_s3_bucket.logs[0].bucket}.s3.amazonaws.com"
      prefix          = "cloudfront/${var.name_prefix}"
    }
  }

  tags = {
    Name = "${var.name_prefix}-cloudfront"
  }

  #depends_on = [aws_cloudfront_origin_access_control.main]
}

# ── Cache Policy ─────────────────────────────────────────────────────────────
resource "aws_cloudfront_cache_policy" "main" {
  name        = "${var.name_prefix}-cache-policy"
  comment     = "Cache policy for ${var.name_prefix}"
  default_ttl = var.default_ttl
  min_ttl     = var.min_ttl
  max_ttl     = var.max_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Origin", "Referer", "User-Agent", "Host"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

# ── Origin Request Policy ────────────────────────────────────────────────────
resource "aws_cloudfront_origin_request_policy" "main" {
  name    = "${var.name_prefix}-origin-request-policy"
  comment = "Origin request policy for ${var.name_prefix}"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
  header_behavior = "whitelist"
  headers {
    items = [
      "Authorization",
      "Origin",
      "Referer",
      "User-Agent",
      "Host"
      # Gardez seulement les plus essentiels
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# ── Response Headers Policy (Sécurité) ──────────────────────────────────────
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${var.name_prefix}-security-headers"
  comment = "Security headers for ${var.name_prefix}"

  security_headers_config {
    # HSTS - Strict-Transport-Security
    strict_transport_security {
      access_control_max_age_sec = var.enabled_security_headers.hsts_max_age_seconds
      include_subdomains         = var.enabled_security_headers.hsts_include_subdomains
      preload                    = var.enabled_security_headers.hsts_preload
      override                   = true
    }

    # X-Content-Type-Options
    content_type_options {
      override = true
    }

    # X-Frame-Options
    frame_options {
      frame_option = var.enabled_security_headers.x_frame_options_value
      override     = true
    }

    # X-XSS-Protection
    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }

  # CORS Configuration
  cors_config {
    access_control_allow_credentials = true
    access_control_allow_headers {
      items = ["Accept", "Authorization", "Content-Type", "Origin", "Referer", "User-Agent", "X-Requested-With"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    }
    access_control_allow_origins {
      items = ["*"]
    }
    access_control_max_age_sec = 86400
    origin_override            = true
  }

}

# ── Bucket S3 pour les logs CloudFront ──────────────────────────────────────
resource "aws_s3_bucket" "logs" {
  count = var.enable_access_logs && var.log_bucket_name == null ? 1 : 0

  bucket        = "${var.name_prefix}-cf-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.name_prefix}-cf-logs"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.enable_access_logs && var.log_bucket_name == null ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.enable_access_logs && var.log_bucket_name == null ? 1 : 0

  bucket                  = aws_s3_bucket.logs[0].id
  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

# ── CloudFront Function ──────────────────────────────────────────────────────
resource "aws_cloudfront_function" "security_headers" {
  name    = "${var.name_prefix}-security-function"
  runtime = "cloudfront-js-2.0"
  comment = "Security function for ${var.name_prefix}"

  code = <<-EOF
    function handler(event) {
      var request = event.request;
      var headers = request.headers;
      
      // Ajouter des headers de sécurité
      headers['x-content-type-options'] = { value: 'nosniff' };
      headers['x-frame-options'] = { value: 'SAMEORIGIN' };
      headers['x-xss-protection'] = { value: '1; mode=block' };
      headers['referrer-policy'] = { value: 'no-referrer-when-downgrade' };
      
      // Bloquer les requêtes avec User-Agent suspects (optionnel)
      if (headers['user-agent'] && headers['user-agent'].value) {
        var ua = headers['user-agent'].value.toLowerCase();
        if (ua.includes('python') || ua.includes('nmap') || ua.includes('nikto')) {
          return {
            statusCode: 403,
            statusDescription: 'Forbidden'
          };
        }
      }
      
      return request;
    }
  EOF
}