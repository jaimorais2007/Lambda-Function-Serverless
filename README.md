# Lambda-Function-Serverless

Função AWS Lambda (Node.js 20.x) que autentica um cliente por CPF:

1. Valida o CPF (dígitos verificadores).
2. Consulta a existência do cliente e se está ativo no banco de dados PostgreSQL (RDS),
   no schema real da aplicação principal ([`Aplicacao-principal-executando-em-Kubernetes`](https://github.com/jaimorais2007/Aplicacao-principal-executando-em-Kubernetes),
   tabela EF Core `Customers`).
3. Se o cliente existir e não estiver inativo, emite um token JWT.

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
| Cliente inativo | 403 | `{ "message": "Cliente inativo, não apto a autenticar." }` |
| Sucesso | 200 | `{ "token", "tokenType": "Bearer", "expiresIn" }` |

## Variáveis de ambiente

| Variável | Descrição |
|---|---|
| `RDS_HOSTNAME` | Endpoint do PostgreSQL (RDS) |
| `RDS_PORT` | Porta do PostgreSQL (padrão `5432`) |
| `RDS_USERNAME` | Usuário de conexão |
| `RDS_PASSWORD` | Senha de conexão |
| `RDS_DB_NAME` | Nome do banco |
| `CUSTOMERS_TABLE` | Tabela de clientes consultada (padrão `Customers`, igual ao `DbSet<Customer>` do EF Core) |
| `JWT_SECRET` | Segredo usado para assinar o token |
| `JWT_EXPIRES_IN` | Expiração do token (ex: `1h`) |

A consulta é `SELECT "Id", "Inactive" FROM "Customers" WHERE "Document_Value" = $1`,
batendo com o schema real gerado pelo EF Core (`OficinaDbContext`/migration
`InitialCreate`): CPF/CNPJ fica na coluna `Document_Value` (owned entity `Document`), e
não existe coluna de "status" — só o booleano `Inactive`.

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

## Free tier

- `memory_size = 128` (mínimo), o suficiente para essa função e o que mantém o uso
  dentro do free tier de Lambda.
- Sem NAT Gateway/VPC Link: a Lambda fica na mesma subnet pública do EC2 e acessa o
  Postgres diretamente pelo IP privado, sem custo de rede adicional.
- O log group do CloudWatch (`/aws/lambda/oficina-mecanica-authenticate`) **não** é
  criado pelo Terraform — o usuário `dev-techchallenge` não tem `logs:CreateLogGroup`.
  A própria Lambda cria o log group automaticamente na primeira execução (usando a
  permissão da própria role de execução), mas fica com retenção infinita. Se
  `logs:CreateLogGroup`/`logs:PutRetentionPolicy` forem liberados no futuro, vale
  recriar o recurso `aws_cloudwatch_log_group` com `retention_in_days` para não
  acumular custo de armazenamento no CloudWatch Logs ao longo do tempo.

Testado com `terraform plan`/`apply` na conta real (168126498555, usuário
`dev-techchallenge`).

## Outputs

- `authenticate_lambda_arn`
- `authenticate_lambda_invoke_arn` — usado pela integração `AWS_PROXY` do API Gateway
- `authenticate_lambda_function_name` — usado na permissão do API Gateway
- `lambda_exec_role_arn` / `lambda_exec_role_name`
