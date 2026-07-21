variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "sg_app_id" { type = string }
variable "alb_target_group_arn" { type = string }
variable "container_image" { type = string }
variable "container_port" { type = number }
variable "task_cpu" { type = number }
variable "task_memory" { type = number }
variable "ecs_desired_count" { 
    type = number
    default     = 3  # ✅ Valeur par défaut 
}
variable "ecs_min_count" { 
    type = number 
    default     = 3  # ✅ Valeur par défaut
}
variable "ecs_max_count" { 
    type = number 
    default     = 3  # ✅ Valeur par défaut
}
variable "cpu_scaling_target" { 
    type = number 
    default     = 70  # ✅ Valeur par défaut
    
}
variable "execution_role_arn" { type = string }
variable "task_role_arn" { type = string }
variable "log_group_name" { type = string }
variable "db_secret_arn" { type = string }
variable "db_endpoint" { type = string }
variable "db_name" { type = string }
