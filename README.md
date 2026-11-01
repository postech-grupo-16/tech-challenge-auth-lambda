# Tech Challenge — Auth Lambda

Function Serverless (Node.js) que autentica clientes via CPF, e o API Gateway que a expõe publicamente e protege as rotas sensíveis da aplicação.

Faz parte do conjunto de 4 repositórios da Fase 3 do Tech Challenge (16SOAT):

| Repositório | Responsabilidade |
|---|---|
| [tech-challenge-app](https://github.com/Gabrielfsg/tech-challenge-app) | API Spring Boot + manifests K8s da aplicação + CI/CD |
| [tech-challenge-infra-k8s](https://github.com/Gabrielfsg/tech-challenge-infra-k8s) | Terraform: VPC, cluster EKS, node group, ECR |
| [tech-challenge-infra-db](https://github.com/Gabrielfsg/tech-challenge-infra-db) | Terraform: banco de dados gerenciado (RDS PostgreSQL) |
| **tech-challenge-auth-lambda** (este) | Function Serverless de autenticação via CPF + API Gateway |

## Dependência

Precisa que [tech-challenge-infra-k8s](https://github.com/Gabrielfsg/tech-challenge-infra-k8s) e [tech-challenge-infra-db](https://github.com/Gabrielfsg/tech-challenge-infra-db) já tenham sido aplicados — este repositório lê a VPC e o endpoint/credenciais do RDS via SSM Parameter Store.

## Arquitetura

```
Cliente                 API Gateway (HTTP API)              Lambdas                RDS
  │                            │                                │                   │
  ├─ POST /auth/cpf ──────────▶│── AWS_PROXY ──────────────▶ auth-cpf ──consulta──▶│
  │                            │                                │ emite JWT (HS256) │
  │◀─────────── 200 {accessToken} ─────────────────────────────│                   │
  │                            │                                                    
  ├─ GET /clientes (Bearer) ──▶│── authorizer (valida JWT) ──▶ authorizer           
  │                            │── HTTP_PROXY (se autorizado) ──▶ tech-challenge-app (EKS)
```

- **`POST /auth/cpf`** (rota pública): [`src/authCpf.js`](src/authCpf.js) — valida o CPF (dígito verificador), consulta `clientes` no RDS por `cpf_cnpj`, confere `status = 'ATIVO'`, e emite um JWT HS256 no mesmo formato que o `tech-challenge-app` já usa (`issuer`, `iat`, `exp`, `sub`, claim `role`), assinado com o mesmo segredo compartilhado — o Resource Server do Spring aceita o token sem nenhuma mudança.
- **Authorizer** ([`src/authorizer.js`](src/authorizer.js)): Lambda authorizer do API Gateway (REQUEST, payload 2.0) que valida o `Authorization: Bearer <token>` antes de encaminhar para a aplicação. Defesa em profundidade — o Spring continua validando o token de novo do seu lado.
- **Proxy para a aplicação**: rota `ANY /{proxy+}` → `tech-challenge-app` no EKS, protegida pelo authorizer acima. Só é criada quando `app_backend_url` está preenchida (ver [Fase 4](#fase-4-ligar-o-proxy-para-a-aplicação) abaixo).

## Estrutura

```
src/
├── authCpf.js      # Handler: POST /auth/cpf
├── authorizer.js    # Handler: Lambda authorizer
├── jwt.js            # Emissão/validação do JWT (segredo compartilhado)
├── db.js              # Consulta a tabela clientes no RDS
└── cpf.js              # Validação de CPF (dígito verificador)

test/
└── cpf.test.js       # Testes unitários da validação de CPF

infra/                 # Terraform: Lambdas, API Gateway, Security Group
```

## Rodando os testes

```bash
npm install
npm test
```

## Deploy

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars com o jwt_secret real (mesmo valor do tech-challenge-app)

cd ..
npm ci --omit=dev
mkdir -p build && zip -r build/lambda.zip src node_modules package.json -x '*.test.js'

cd infra
terraform init -backend-config=environments/production.s3.tfbackend
terraform apply -var-file=environments/production.tfvars
```

> **Ambientes:** troque `production` por `homolog` para operar a stack de homologação (nomes com sufixo `-homolog`, parâmetros SSM em `/tech-challenge-homolog/*`, state em outra key do mesmo bucket). Ao alternar entre ambientes na mesma pasta, rode `terraform init -reconfigure -backend-config=...`.

```bash
terraform output auth_cpf_endpoint
```

## Testando

```bash
curl -X POST "$(terraform -chdir=infra output -raw api_gateway_url)/auth/cpf" \
  -H "Content-Type: application/json" \
  -d '{"cpf": "52998224725"}'
```

## Fase 4: ligar o proxy para a aplicação

Depois que o [tech-challenge-app](https://github.com/Gabrielfsg/tech-challenge-app) expuser a API via `Service` tipo `LoadBalancer` no EKS, preencha `app_backend_url` em `terraform.tfvars` (ou a variável de repositório `APP_BACKEND_URL` no GitHub, usada pelo CI) com a URL do ELB e rode `terraform apply` de novo — isso cria a rota `ANY /{proxy+}` protegida pelo authorizer.

## CI/CD

[`.github/workflows/pipeline.yml`](.github/workflows/pipeline.yml): roda os testes do Node em todo push/PR; em PR, faz só `terraform plan`; em push na `main` (produção) ou na `homolog` (homologação), ou via `workflow_dispatch`, empacota a Lambda e roda `terraform apply`. Requer os secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` (credenciais do AWS Academy Learner Lab) e `TF_VAR_JWT_SECRET`, mais a variável de repositório `APP_BACKEND_URL` (opcional, Fase 4). Para homologação: secret `TF_VAR_JWT_SECRET_HOMOLOG` e variável `APP_BACKEND_URL_HOMOLOG`.

A branch `main` é protegida — merges só via Pull Request.

---

Desenvolvido como Tech Challenge — Pós-Graduação em Arquitetura de Software (FIAP/16SOAT).
