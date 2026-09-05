# Lambda-Function-Serverless

Função AWS Lambda (Node.js 20.x) que autentica um cliente por CPF:

1. Valida o CPF (dígitos verificadores).
2. Consulta a existência e o status do cliente no banco de dados PostgreSQL (RDS).
3. Se o cliente existir e o status estiver na lista de status permitidos, emite um token JWT.

## Requisição

```
POST /authenticate
Content-Type: application/json

{ "cpf": "123.456.789-09" }
```

## Respostas

| Situação | Status | Corpo |
|---|---|---|
| CPF inválido | 400 | `{ "message": "CPF inválido." }` |
| Cliente não encontrado | 404 | `{ "message": "Cliente não encontrado." }` |
| Status não permitido | 403 | `{ "message": "Cliente com status \"X\" não está apto a autenticar." }` |
| Sucesso | 200 | `{ "token", "tokenType": "Bearer", "expiresIn" }` |

## Variáveis de ambiente

| Variável | Descrição |
|---|---|
| `RDS_HOSTNAME` | Endpoint do PostgreSQL (RDS) |
| `RDS_PORT` | Porta do PostgreSQL (padrão `5432`) |
| `RDS_USERNAME` | Usuário de conexão |
| `RDS_PASSWORD` | Senha de conexão |
| `RDS_DB_NAME` | Nome do banco |
| `CUSTOMERS_TABLE` | Tabela de clientes consultada (padrão `customers`) |
| `JWT_SECRET` | Segredo usado para assinar o token |
| `JWT_EXPIRES_IN` | Expiração do token (ex: `1h`) |
| `ALLOWED_STATUSES` | Status aptos a autenticar, separados por vírgula (ex: `ATIVO,PENDENTE`) |

A tabela `customers`/`CUSTOMERS_TABLE` precisa ter, no mínimo, as colunas `cpf` e `status`.

## Deploy (Terraform)

Este repositório provisiona a função Lambda e a role de execução via Terraform, e publica o
state em S3 (`versions.tf`) para que o repositório
[`Infraestrutura-Kubernetes-Terraform`](../Infraestrutura-Kubernetes-Terraform) possa
integrá-la a um API Gateway através de `terraform_remote_state`.

```bash
npm ci --omit=dev
# empacota index.js + node_modules em ../authenticate.zip
zip -r ../authenticate.zip index.js node_modules package.json

terraform init
terraform apply \
  -var="rds_hostname=<endpoint-do-rds>" \
  -var="rds_username=<usuario>" \
  -var="rds_password=<senha>" \
  -var="rds_db_name=<banco>"
```

Por padrão, `subnet_ids` já aponta para a subnet da instância EC2 do Tech Challenge
(`subnet-00c1dffa4498744cf`, `vpc-04688278103fa8423`), e a Lambda ganha automaticamente
um security group próprio (`lambda_security_group_id`, no output) usado pelo repositório
[`Infra-Banco-de-Dados-Gerenciado-Terraform`](https://github.com/jaimorais2007/Infra-Banco-de-Dados-Gerenciado-Terraform)
para liberar a porta 5432. Aplique este repositório **antes** daquele.

## ⚠️ Permissões AWS necessárias

O usuário IAM usado no projeto (`dev-techchallenge`) hoje só tem permissão de leitura em
EC2 e de gerenciar Security Groups — **isso não é suficiente para este repositório**.
Testado na conta real (168126498555): `lambda:ListFunctions` e `apigateway:GET` retornam
`AccessDenied`, e não há permissão de `s3:*` para o backend remoto. Para aplicar este
Terraform, é preciso adicionar ao usuário (ou a uma role assumida por ele) algo como:

- `lambda:*` na função `oficina-mecanica-authenticate`
- `iam:CreateRole`, `iam:PutRolePolicy`, `iam:AttachRolePolicy`, `iam:PassRole` na role
  `oficina-mecanica-lambda-exec-role`
- `ec2:CreateSecurityGroup`, `ec2:DescribeSubnets`, `ec2:DescribeSecurityGroups` (para o
  security group da Lambda)
- `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` no bucket `meu-bucket-terraform-state`
  (backend do state)

## Outputs

- `authenticate_lambda_arn`
- `authenticate_lambda_invoke_arn` — usado pela integração `AWS_PROXY` do API Gateway
- `authenticate_lambda_function_name` — usado na permissão do API Gateway
- `lambda_exec_role_arn` / `lambda_exec_role_name`
