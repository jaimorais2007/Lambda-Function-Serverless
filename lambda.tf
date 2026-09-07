data "aws_subnet" "selected" {
  count = length(var.subnet_ids) > 0 ? 1 : 0
  id    = var.subnet_ids[0]
}

resource "aws_security_group" "lambda_sg" {
  count       = length(var.subnet_ids) > 0 ? 1 : 0
  name        = "${var.project_name}-lambda-sg"
  description = "Security group da Lambda de autenticacao"
  vpc_id      = data.aws_subnet.selected[0].vpc_id

  egress {
    description = "Saida irrestrita (necessaria para acessar o Postgres/RDS)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# O usuario dev-techchallenge nao tem permissao de logs:CreateLogGroup, entao o log
# group nao e criado explicitamente aqui - a propria Lambda cria automaticamente na
# primeira execucao, usando a permissao que ja vem da role de execucao dela
# (AWSLambdaBasicExecutionRole). Fica sem retention_in_days definido (retencao
# infinita) ate essa permissao ser liberada; ajustar manualmente ou reativar este
# recurso quando "logs:CreateLogGroup"/"logs:PutRetentionPolicy" forem concedidos.
resource "aws_lambda_function" "authenticate" {
  function_name = "${var.project_name}-authenticate"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  memory_size   = 128 # minimo permitido; suficiente para essa funcao e mantem o uso dentro do free tier

  filename         = "${path.module}/../authenticate.zip"
  source_code_hash = filebase64sha256("${path.module}/../authenticate.zip")

  environment {
    variables = {
      RDS_HOSTNAME     = var.rds_hostname
      RDS_PORT         = var.rds_port
      RDS_USERNAME     = var.rds_username
      RDS_PASSWORD     = var.rds_password
      RDS_DB_NAME      = var.rds_db_name
      CUSTOMERS_TABLE  = var.customers_table
      JWT_SECRET       = var.jwt_secret
      JWT_EXPIRES_IN   = var.jwt_expires_in
      ALLOWED_STATUSES = var.allowed_statuses
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = concat(var.security_group_ids, aws_security_group.lambda_sg[*].id)
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  count      = length(var.subnet_ids) > 0 ? 1 : 0
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# A permissão para o API Gateway invocar esta função é criada no repositório
# Infraestrutura-Kubernetes-Terraform (infra/gateway.tf), que consome os outputs
# deste state via terraform_remote_state e restringe o invocador à API criada lá.
