output "api_gateway_url" {
  description = "URL publica do API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "auth_cpf_endpoint" {
  description = "Endpoint completo de autenticacao via CPF"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/auth/cpf"
}
