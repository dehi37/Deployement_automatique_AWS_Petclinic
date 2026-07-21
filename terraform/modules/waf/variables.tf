variable "name_prefix" {
  type = string
}

variable "alb_arn" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "cloudfront_distribution_id" {
  type    = string
  default = null
}
variable "enable_waf_logging" {
  description = "Enable WAF logging (can exceed limits)"
  type        = bool
  default     = false  # Mettre à false pour éviter la limite
}

variable "enable_rate_limiting" {
  type    = bool
  default = true
}

variable "rate_limit" {
  description = "Nombre de requêtes par 5 minutes avant blocage"
  type        = number
  default     = 2000
}

variable "blocked_ips" {
  description = "Liste des IPs à bloquer (CIDR)"
  type        = list(string)
  default     = []
}

variable "allowed_countries" {
  description = "Liste des codes pays autorisés (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = ["FR", "SN", "US", "GB", "DE", "CA"]
}

variable "aws_region" {
  type = string
}