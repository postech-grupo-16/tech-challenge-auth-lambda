# Le a rede (tech-challenge-infra-k8s) e o banco (tech-challenge-infra-db)
# via SSM Parameter Store, sem acoplar os Terraform states dos 3 repositorios.
data "aws_ssm_parameter" "vpc_id" {
  name = "/tech-challenge/vpc_id"
}

data "aws_ssm_parameter" "vpc_cidr" {
  name = "/tech-challenge/vpc_cidr"
}

data "aws_ssm_parameter" "subnet_ids" {
  name = "/tech-challenge/subnet_ids"
}

data "aws_ssm_parameter" "rds_endpoint" {
  name = "/tech-challenge/rds_endpoint"
}

data "aws_ssm_parameter" "rds_port" {
  name = "/tech-challenge/rds_port"
}

data "aws_ssm_parameter" "rds_db_name" {
  name = "/tech-challenge/rds_db_name"
}

data "aws_ssm_parameter" "rds_user" {
  name            = "/tech-challenge/rds_user"
  with_decryption = true
}

data "aws_ssm_parameter" "rds_password" {
  name            = "/tech-challenge/rds_password"
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
