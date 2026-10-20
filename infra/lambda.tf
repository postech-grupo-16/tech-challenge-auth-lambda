locals {
  lambda_env = {
    JWT_SECRET  = var.jwt_secret
    DB_HOST     = data.aws_ssm_parameter.rds_endpoint.value
    DB_PORT     = data.aws_ssm_parameter.rds_port.value
    DB_NAME     = data.aws_ssm_parameter.rds_db_name.value
    DB_USER     = data.aws_ssm_parameter.rds_user.value
    DB_PASSWORD = data.aws_ssm_parameter.rds_password.value
  }
}

# Emite o token: POST /auth/cpf (rota publica no API Gateway).
resource "aws_lambda_function" "auth_cpf" {
  function_name = "${var.project_name}-auth-cpf"
  role          = local.lab_role_arn
  handler       = "src/authCpf.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  memory_size   = 256

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  vpc_config {
    subnet_ids         = local.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }

  tags = var.tags
}

# Valida o token nas rotas protegidas (Lambda authorizer do API Gateway).
# So precisa do JWT_SECRET - nao consulta o banco.
resource "aws_lambda_function" "authorizer" {
  function_name = "${var.project_name}-auth-authorizer"
  role          = local.lab_role_arn
  handler       = "src/authorizer.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  memory_size   = 128

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "apigw_auth_cpf" {
  statement_id  = "AllowAPIGatewayInvokeAuthCpf"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_cpf.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
