resource "aws_lambda_function" "authenticate" {
  function_name = "${var.project_name}-authenticate"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  filename         = "${path.module}/../authenticate.zip"
  source_code_hash = filebase64sha256("${path.module}/../authenticate.zip")

  environment {
    variables = {
      CUSTOMERS_TABLE  = aws_dynamodb_table.customers.name
      JWT_SECRET       = var.jwt_secret
      JWT_EXPIRES_IN   = var.jwt_expires_in
      ALLOWED_STATUSES = var.allowed_statuses
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

resource "aws_iam_role_policy" "dynamodb_read" {
  name = "${var.project_name}-dynamodb-read"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem"]
      Resource = aws_dynamodb_table.customers.arn
    }]
  })
}