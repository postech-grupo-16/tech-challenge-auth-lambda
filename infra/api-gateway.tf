resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "Entrada publica do Tech Challenge: auth via CPF + proxy para a aplicacao"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  # Logs estruturados em JSON, com correlacao via requestId - alimentam o
  # dashboard de observabilidade (Fase 5).
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      authorizerError  = "$context.authorizer.error"
      latencyMs        = "$context.responseLatency"
    })
  }

  tags = var.tags
}

# --- Rota publica: emissao do token ---

resource "aws_apigatewayv2_integration" "auth_cpf" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_cpf.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_cpf" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /auth/cpf"
  target    = "integrations/${aws_apigatewayv2_integration.auth_cpf.id}"
}

# --- Authorizer (Lambda) para as rotas protegidas ---

resource "aws_apigatewayv2_authorizer" "jwt_cpf" {
  api_id                            = aws_apigatewayv2_api.main.id
  name                              = "${var.project_name}-cpf-authorizer"
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
  authorizer_result_ttl_in_seconds  = 0
}

# --- Proxy para a aplicacao (tech-challenge-app), rotas protegidas ---
# So e criado depois que app_backend_url estiver preenchida (Fase 4, apos o
# tech-challenge-app expor a API via Service LoadBalancer). Ate la, o
# Gateway so expoe /auth/cpf.

resource "aws_apigatewayv2_integration" "app_proxy" {
  count                  = var.app_backend_url != "" ? 1 : 0
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "${var.app_backend_url}/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "app_proxy" {
  count              = var.app_backend_url != "" ? 1 : 0
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.app_proxy[0].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_cpf.id
}
