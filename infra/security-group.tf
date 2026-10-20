# A Lambda roda dentro da VPC (precisa alcancar o RDS, que nao e publico).
# Egress restrito a Postgres dentro da propria VPC - a Lambda nao precisa de
# acesso a internet (nao chama nenhuma outra API AWS; logs vao pro
# CloudWatch pelo control-plane do proprio Lambda, nao pela rede da VPC),
# entao nao ha NAT Gateway nem VPC Endpoints aqui.
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-auth-lambda"
  description = "Egress da Lambda de autenticacao, restrito ao Postgres da VPC"
  vpc_id      = local.vpc_id

  egress {
    description = "Postgres (RDS) dentro da VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  tags = var.tags
}
