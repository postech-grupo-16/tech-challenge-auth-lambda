locals {
  # Em producao os nomes ficam exatamente como antes (sem sufixo), para nao
  # forcar a recriacao de nada; os demais ambientes ganham o sufixo
  # (ex.: tech-challenge-homolog-auth-cpf, /tech-challenge-homolog/jwt_secret).
  # Precisa bater com o mesmo calculo em tech-challenge-infra-k8s e
  # tech-challenge-infra-db, de onde vem a rede e o banco lidos em data.tf.
  name_prefix = var.environment == "production" ? var.project_name : "${var.project_name}-${var.environment}"
  ssm_prefix  = "/${local.name_prefix}"
}
