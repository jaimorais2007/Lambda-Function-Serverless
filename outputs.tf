output "authenticate_lambda_arn" {
  description = "ARN da Lambda de autenticação"
  value       = aws_lambda_function.authenticate.arn
}

output "authenticate_lambda_invoke_arn" {
  description = "Invoke ARN da Lambda (usado em integrações com API Gateway)"
  value       = aws_lambda_function.authenticate.invoke_arn
}

output "authenticate_lambda_function_name" {
  description = "Nome da função Lambda de autenticação"
  value       = aws_lambda_function.authenticate.function_name
}

output "authorizer_lambda_arn" {
  description = "ARN da Lambda authorizer (valida o JWT emitido por /authenticate nas demais rotas)"
  value       = aws_lambda_function.authorizer.arn
}

output "authorizer_lambda_invoke_arn" {
  description = "Invoke ARN da Lambda authorizer (usado no aws_apigatewayv2_authorizer)"
  value       = aws_lambda_function.authorizer.invoke_arn
}

output "authorizer_lambda_function_name" {
  description = "Nome da função Lambda authorizer"
  value       = aws_lambda_function.authorizer.function_name
}

output "lambda_exec_role_arn" {
  description = "ARN da role de execução da Lambda"
  value       = aws_iam_role.lambda_exec.arn
}

output "lambda_exec_role_name" {
  description = "Nome da role de execução da Lambda"
  value       = aws_iam_role.lambda_exec.name
}

output "lambda_security_group_id" {
  description = "Security group da Lambda (quando anexada a uma VPC), usado para liberar o acesso dela ao Postgres/RDS"
  value       = try(aws_security_group.lambda_sg[0].id, null)
}