# Le a rede (tech-challenge-infra-k8s) e o banco (tech-challenge-infra-db)
# via SSM Parameter Store, sem acoplar os Terraform states dos 3 repositorios.
data "aws_ssm_parameter" "vpc_id" {
  name = "${local.ssm_prefix}/vpc_id"
}

data "aws_ssm_parameter" "vpc_cidr" {
  name = "${local.ssm_prefix}/vpc_cidr"
}

data "aws_ssm_parameter" "subnet_ids" {
  name = "${local.ssm_prefix}/subnet_ids"
}

data "aws_ssm_parameter" "rds_endpoint" {
  name = "${local.ssm_prefix}/rds_endpoint"
}

data "aws_ssm_parameter" "rds_port" {
  name = "${local.ssm_prefix}/rds_port"
}

data "aws_ssm_parameter" "rds_db_name" {
  name = "${local.ssm_prefix}/rds_db_name"
}

data "aws_ssm_parameter" "rds_user" {
  name            = "${local.ssm_prefix}/rds_user"
  with_decryption = true
}

data "aws_ssm_parameter" "rds_password" {
  name            = "${local.ssm_prefix}/rds_password"
  with_decryption = true
}

data "aws_caller_identity" "current" {}

locals {
  vpc_id     = data.aws_ssm_parameter.vpc_id.value
  vpc_cidr   = data.aws_ssm_parameter.vpc_cidr.value
  subnet_ids = split(",", data.aws_ssm_parameter.subnet_ids.value)

  # AWS Academy: so a role pre-existente LabRole esta disponivel, nao da
  # pra criar roles/policies IAM novas (ver mesma decisao em
  # tech-challenge-infra-k8s/eks-cluster.tf).
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}
