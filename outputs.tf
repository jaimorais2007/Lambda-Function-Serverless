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

output "lambda_exec_role_arn" {
  description = "ARN da role de execução da Lambda"
  value       = aws_iam_role.lambda_exec.arn
}

output "lambda_exec_role_name" {
  description = "Nome da role de execução da Lambda"
  value       = aws_iam_role.lambda_exec.name
}