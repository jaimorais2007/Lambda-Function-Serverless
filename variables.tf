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
  description = "Segredo usado para assinar os tokens JWT (defina via terraform.tfvars ou -var, não versione o valor real)"
  type        = string
  sensitive   = true
}

variable "jwt_expires_in" {
  description = "Tempo de expiração do token JWT"
  type        = string
  default     = "1m"
}

variable "rds_hostname" {
  description = "Endpoint do banco de dados PostgreSQL (RDS) usado para consultar o cliente pelo CPF"
  type        = string
}

variable "rds_port" {
  description = "Porta do banco de dados PostgreSQL (RDS)"
  type        = number
  default     = 5432
}

variable "rds_username" {
  description = "Usuário de conexão com o banco de dados RDS"
  type        = string
}

variable "rds_password" {
  description = "Senha de conexão com o banco de dados RDS"
  type        = string
  sensitive   = true
}

variable "rds_db_name" {
  description = "Nome do banco de dados no RDS"
  type        = string
}

variable "rds_ssl" {
  description = "Usar SSL na conexão com o Postgres ('true'/'false'). O Postgres deste projeto roda via docker-compose sem certificado, então o padrão é 'false'."
  type        = string
  default     = "false"
}

variable "customers_table" {
  description = "Nome da tabela de clientes consultada no RDS (schema real do EF Core: tabela \"Customers\", CPF na coluna \"Document_Value\", ativo/inativo na coluna \"Inactive\")"
  type        = string
  default     = "Customers"
}

variable "subnet_ids" {
  description = "Subnets usadas para colocar a Lambda na mesma VPC/subnet do EC2 que roda o Postgres (deixe vazio se o RDS for publicamente acessível). Default: subnet da instância do Tech Challenge (subnet-00c1dffa4498744cf, vpc-04688278103fa8423)."
  type        = list(string)
  default     = ["subnet-00c1dffa4498744cf"]
}

variable "security_group_ids" {
  description = "Security groups adicionais (além do criado automaticamente para a Lambda) aplicados quando ela é colocada em uma VPC"
  type        = list(string)
  default     = []
}
