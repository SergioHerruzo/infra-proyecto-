# 🎮 Indie Games — Infraestructura AWS con Terraform

Infraestructura completa desplegada sobre **AWS Academy** usando Terraform, con red privada (VPC), autenticación, API REST securizada, almacenamiento y hosting de frontend.

---

## 📐 Arquitectura general

```
┌─────────────────────────────────────────────────────────────────┐
│                         USUARIO FINAL                           │
└───────────────────────────────┬─────────────────────────────────┘
                                │ HTTPS
                ┌───────────────┴───────────────┐
                ▼                               ▼
┌───────────────────────────────┐ ┌───────────────────────────────┐
│     AWS Amplify (PROD)        │ │      AWS Amplify (DEV)        │
│ Repo: Usuarios (Rama main)    │ │ Repo: Developers (Rama dev)   │
│ URL: tudominio.com            │ │ URL: dev.tudominio.com        │
└───────────────┬───────────────┘ └───────────────┬───────────────┘
                │                                 │
                └────────────────┬────────────────┘
                                 │
               ┌────────────────┼──────────────────┐
               │                │                  │
               ▼                ▼                  ▼
   ┌──────────────────┐  ┌──────────────┐   ┌─────────────────┐
   │  AWS Cognito     │  │  WAFv2       │   │  CloudWatch     │
   │  User Pool       │  │  (firewall)  │   │  Logs + X-Ray   │
   │  + App Client    │  └──────┬───────┘   └─────────────────┘
   │  + Hosted UI     │         │
   └──────────────────┘         ▼
                      ┌──────────────────────┐
                      │  API Gateway REST    │
                      │  (Regional, prod)    │
                      │  · Cognito Authorizer│
                      │  · Request Validator │
                      │  · Usage Plan + Key  │
                      │  · Throttling        │
                      └──────────┬───────────┘
                                 │ HTTP Proxy
               ┌─────────────────┼─────────────────┐
               │   VPC (10.0.0.0/16)               │
               │                                   │
               ▼                                   ▼
  ┌───────────────────────────┐       ┌───────────────────────────┐
  │ Subnets Públicas (AZ a/b) │       │ Subnets Privadas (AZ a/b) │
  ├───────────────────────────┤       ├───────────────────────────┤
  │ · Elastic Beanstalk       │       │ · RDS PostgreSQL          │
  │ · ECS Fargate Service     │       │ · Lambda (Utility)        │
  │ · Bastion Host (EIP)      │       └─────────────┬─────────────┘
  │ · NAT Gateway             │                     │
  └─────────────┬─────────────┘                     │
                │             Salida Internet       │
                ◀───────────────────────────────────┘
                                 │
                                 ▼
                     ┌──────────────────────┐
                     │  S3 Bucket           │
                     │  (game_storage)      │
                     │  acceso privado      │
                     └──────────────────────┘
```

---

## 📦 Recursos desplegados

### 🌐 Red y Seguridad — `vpc.tf` / `bastion.tf`
| Recurso | Detalle |
|---|---|
| `aws_vpc` | CIDR `10.0.0.0/16` |
| `aws_subnet` | 2 Públicas (app) + 2 Privadas (datos/Lambda) |
| `aws_internet_gateway` | Salida a Internet para subnets públicas |
| `aws_nat_gateway` | Salida a Internet para la Lambda (acceso Cognito) |
| `aws_instance` (Bastion) | Acceso SSH seguro vía Elastic IP (EIP) y túnel RDS |

### 🔐 Autenticación — `auth.tf`
| Recurso | Nombre | Descripción |
|---|---|---|
| `aws_cognito_user_pool` | `steam-user-pool` | Pool de usuarios con login por email |
| `aws_cognito_user_pool_client` | `steam-app-client` | Cliente OAuth 2.0 sin secret (SPA/móvil) |
| `aws_cognito_user_pool_domain` | `steam-indio-auth` | Hosted UI para login/registro |

- Tokens: access/id = 1h · refresh = 30 días
- OAuth flows: `code` + `implicit`
- Scopes: `email`, `openid`, `profile`

---

### 🌐 API REST — `api_gateway.tf`
| Recurso | Detalle |
|---|---|
| `aws_api_gateway_rest_api` | API REGIONAL (v1) con compresión habilitada |
| `aws_api_gateway_authorizer` | Cognito JWT (header `Authorization`) |
| `aws_api_gateway_resource` | Único recurso `/{proxy+}` para todo el tráfico |
| `aws_api_gateway_stage` (prod) | X-Ray + access logs en CloudWatch |
| `aws_api_gateway_usage_plan` | 100k req/mes · 100 req/s · burst 200 |

**Seguridad WAFv2:** Protección contra IP maliciosas, OWASP Common Rules, SQL Injection y Rate Limiting.

---

### 🖥️ Compute — `compute_ecs.tf` / `compute_beanstalk.tf`
| Servicio | Recurso | Uso |
|---|---|---|
| ECS Fargate | `steam-cluster` + `game-api` | API de videojuegos (Fargate Service) |
| Elastic Beanstalk | `steam-workers-prod` | Workers / procesos en segundo plano (Docker) |

- **Networking:** Desplegados en subnets públicas con IP pública asignada (ahorro de NAT Gateway en Academy).
- **Seguridad:** SGs específicos que solo permiten tráfico HTTP desde el API Gateway.

---

### 🗃️ Datos — `database_storage.tf`
| Recurso | Detalle |
|---|---|
| `aws_db_instance` (PostgreSQL 15) | `db.t3.micro` en subnets **privadas** |
| `aws_s3_bucket` | Almacenamiento privado de juegos y archivos |
| `aws_security_group` (db_sg) | Solo permite tráfico desde la VPC y el Bastion |

---

### 📱 Frontend — `amplify.tf`
| Entorno | Repositorio | URL |
|---|---|---|
| **Producción** | `var.github_repo_url` | `www.tudominio.com` |
| **Desarrollo** | `var.github_repo_url_dev` | `dev.tudominio.com` |

- **Variables de entorno inyectadas:** `VITE_AWS_USER_POOL_ID`, `VITE_AWS_USER_POOL_CLIENT_ID`, `VITE_API_URL`.
- **CI/CD:** Cada aplicación es independiente y se despliega automáticamente al hacer push a su respectivo repositorio.

---

## 🚀 Instrucciones de despliegue

### 1. Configurar variables
Crea tu `terraform.tfvars` basándote en el example:

```hcl
aws_region          = "us-east-1"
domain_name         = "tudominio.com"
github_repo_url     = "https://github.com/usuario/repo-prod"
github_repo_url_dev = "https://github.com/usuario/repo-dev"
github_token        = "ghp_..."
my_ip_cidr       = "1.2.3.4/32" # Opcional (defecto: 0.0.0.0/0)
bastion_key_name = "vockey"     # Key pair de Academy (opcional, defecto vockey)
```

### 2. Inicializar y desplegar
```bash
terraform init
terraform apply
```

### 3. Acceso a la Base de Datos (RDS)
La base de datos está en una red privada. Para conectar desde tu PC local:

1. Obtén la IP estática (EIP) del bastion y el endpoint de RDS:
   ```bash
   terraform output bastion_public_ip
   terraform output rds_endpoint
   ```
2. Crea un túnel SSH (usando la EIP):
   ```bash
   ssh -i "vockey.pem" -L 5432:[RDS_ENDPOINT]:5432 ec2-user@[BASTION_EIP]
   ```
3. Conecta tu cliente (DBeaver/psql) a `localhost:5432`.

---

## ⚠️ Consideraciones AWS Academy
- **NAT Gateway:** Se incluye un solo NAT Gateway para permitir que la Lambda en subred privada conecte con Cognito sin perder seguridad.
- **Roles:** Se usa el `LabRole` y el `LabInstanceProfile` pre-existentes.
- **WAF:** Si tu cuenta de Academy tiene restricciones en WAF, comenta el bloque `aws_wafv2_web_acl_association`.

---

## 🗂️ Estructura de ficheros
- `vpc.tf`: Red, subnets, IGW y Route Tables.
- `bastion.tf`: Instancia de acceso seguro y túnel SSH.
- `lambda.tf`: Función Lambda de utilidad integrada en la VPC.
- `lambda_function.py`: Código (placeholder) de la función Lambda.
- `auth.tf`: Cognito User Pool, Client y Dominio.
- `api_gateway.tf`: API Gateway REST + WAF + Authorizer.
- `amplify.tf`: Hosting frontend y CI/CD.
- `compute_*.tf`: Infraestructura de cómputo (ECS/EB).
- `database_storage.tf`: RDS PostgreSQL y S3.
- `outputs.tf`: Información clave post-despliegue.

---

## 📄 Licencia
Proyecto académico — uso educativo.
