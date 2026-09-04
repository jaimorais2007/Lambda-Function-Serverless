variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo usado para nomear os recursos"
  type        = string
  default     = "oficina-mecanica"
}

variable "jwt_secret" {
  description = "Segredo usado para assinar os tokens JWT"
  type        = string
  sensitive   = true
  default     = "da6e77b42314ee792151df810ed6899e39ce6d27f7cdb3da31454b62f91c961b"
}

variable "jwt_expires_in" {
  description = "Tempo de expiração do token JWT"
  type        = string
  default     = "1m"
}

variable "allowed_statuses" {
  description = "Lista de status de cliente aptos a autenticar, separados por vírgula (ex: 'ATIVO,PENDENTE')"
  type        = string
  default     = "ATIVO"
}
