variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto, usado para nomear os recursos"
  type        = string
  default     = "tech-challenge"
}

variable "lambda_zip_path" {
  description = "Caminho do pacote .zip da Lambda (gerado pelo CI antes do apply)"
  type        = string
  default     = "../build/lambda.zip"
}

# Preencha via terraform.tfvars (gitignored) ou TF_VAR_jwt_secret. Precisa
# ser EXATAMENTE o mesmo valor configurado em app.jwt.secret no
# tech-challenge-app (JWT_SECRET no Secret do Kubernetes), senao os tokens
# emitidos aqui nao validam no Resource Server do Spring.
variable "jwt_secret" {
  description = "Chave HMAC compartilhada com o tech-challenge-app para assinar/validar JWT"
  type        = string
  sensitive   = true
}

# URL base da aplicacao no EKS (ex.: http://<elb-dns-name>), preenchida na
# Fase 4 deste projeto depois que tech-challenge-app expuser a API via
# Service LoadBalancer. Enquanto vazia, a rota de proxy nao e criada -
# o API Gateway so expoe /auth/cpf.
variable "app_backend_url" {
  description = "URL do backend da aplicacao para a rota de proxy do API Gateway"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags aplicadas aos recursos"
  type        = map(string)
  default = {
    "Name" = "tech-challenge"
  }
}
