# Publica a URL publica do Gateway e o segredo JWT no SSM, para o CI do
# tech-challenge-app ler na hora do deploy (o Secret do Kubernetes precisa
# do MESMO JWT_SECRET usado aqui, senao os tokens da Lambda nao validam).
resource "aws_ssm_parameter" "api_gateway_url" {
  name  = "/tech-challenge/api_gateway_url"
  type  = "String"
  value = aws_apigatewayv2_api.main.api_endpoint
}

resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/tech-challenge/jwt_secret"
  type  = "SecureString"
  value = var.jwt_secret
}
