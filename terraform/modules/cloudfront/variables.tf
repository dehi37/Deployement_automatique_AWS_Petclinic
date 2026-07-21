variable "name_prefix" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "web_acl_arn" {
  type    = string
  default = null
}

variable "aws_region" {
  type = string
}

variable "enable_geo_restriction" {
  type    = bool
  default = false
}

variable "geo_restriction_locations" {
  description = "Liste des codes pays autorisés (pour CloudFront)"
  type        = list(string)
  default     = ["FR", "SN", "US", "GB", "DE", "CA"]
}

variable "price_class" {
  description = "Price class for CloudFront (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "enable_access_logs" {
  type    = bool
  default = false  # ← Changez true en false
}

variable "log_bucket_name" {
  type    = string
  default = null
}

variable "min_ttl" {
  type    = number
  default = 0
}

variable "default_ttl" {
  type    = number
  default = 3600
}

variable "max_ttl" {
  type    = number
  default = 86400
}

variable "custom_error_responses" {
  description = "Custom error responses for CloudFront"
  type = list(object({
    error_code            = number
    response_page_path    = string
    response_code         = number
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

variable "enabled_security_headers" {
  description = "Ajouter des headers de sécurité personnalisés"
  type = object({
    enable_hsts               = bool
    hsts_max_age_seconds      = number
    hsts_include_subdomains   = bool
    hsts_preload              = bool
    enable_x_content_type     = bool
    enable_x_frame_options    = bool
    x_frame_options_value     = string
    enable_x_xss_protection   = bool
  })
  default = {
    enable_hsts             = true
    hsts_max_age_seconds    = 31536000
    hsts_include_subdomains = true
    hsts_preload            = true
    enable_x_content_type   = true
    enable_x_frame_options  = true
    x_frame_options_value   = "SAMEORIGIN"
    enable_x_xss_protection = true
  }
}