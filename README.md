# 🎮 Steam Indio — Infraestructura AWS con Terraform

Infraestructura completa desplegada sobre **AWS Academy** usando Terraform, con autenticación, API REST securizada, almacenamiento y hosting de frontend.

---

## 📐 Arquitectura general

```
┌─────────────────────────────────────────────────────────────────┐
│                         USUARIO FINAL                           │
└───────────────────────────────┬─────────────────────────────────┘
                                │ HTTPS
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Amplify (Frontend)                        │
│              React/Vite — desplegado desde GitHub               │
│  ENV: VITE_AWS_USER_POOL_ID · VITE_AWS_USER_POOL_CLIENT_ID     │
│        VITE_API_URL                                             │
└───────────────────────────────┬─────────────────────────────────┘
                                │
              ┌─────────────────┼──────────────────┐
              │                 │                  │
              ▼                 ▼                  ▼
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
              │                                   │
              ▼                                   ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│  Elastic Beanstalk      │         │  ECS Fargate            │
│  (Workers / Backend)    │         │  (game-api)             │
│  Docker · SingleInstance│         │  awsvpc · Fargate       │
└───────────┬─────────────┘         └──────────┬──────────────┘
            │                                  │
            └──────────────┬───────────────────┘
                           │
              ┌────────────┼────────────┐
              │                         │
              ▼                         ▼
  ┌───────────────────┐     ┌──────────────────────┐
  │  RDS PostgreSQL   │     │  S3 Bucket           │
  │  db.t3.micro      │     │  (game_storage)      │
  │  encrypted (KMS)  │     │  acceso privado      │
  └───────────────────┘     └──────────────────────┘
```

---

## 📦 Recursos desplegados

### 🔐 Autenticación — `auth.tf`
| Recurso | Nombre | Descripción |
|---|---|---|
| `aws_cognito_user_pool` | `steam-user-pool` | Pool de usuarios con login por email |
| `aws_cognito_user_pool_client` | `steam-app-client` | Cliente OAuth 2.0 sin secret (SPA/móvil) |
| `aws_cognito_user_pool_domain` | `steam-indio-auth` | Hosted UI para login/registro |

- Login por **email**
- Verificación de cuenta por email con código
- Tokens: access/id = 1h · refresh = 30 días
- OAuth flows: `code` + `implicit`
- Scopes: `email`, `openid`, `profile`

---

### 🌐 API REST — `api_gateway.tf`
| Recurso | Detalle |
|---|---|
| `aws_api_gateway_rest_api` | API REGIONAL con compresión habilitada |
| `aws_api_gateway_authorizer` | Cognito JWT (header `Authorization`) |
| `aws_api_gateway_request_validator` | Valida body + parámetros |
| `aws_api_gateway_stage` (prod) | X-Ray + access logs en CloudWatch |
| `aws_api_gateway_method_settings` | Logging INFO + métricas + throttling |
| `aws_api_gateway_usage_plan` | 100k req/mes · 100 req/s · burst 200 |
| `aws_api_gateway_api_key` | Clave de API para el frontend |

**Rutas:**
| Método | Ruta | Auth |
|---|---|---|
| `GET` | `/health` | ❌ Pública |
| `ANY` | `/{proxy+}` | ✅ Cognito JWT |

**Seguridad WAFv2:**
| Regla | Tipo | Acción |
|---|---|---|
| IP Reputation (AWS Managed) | Managed | Block |
| Common Rule Set — OWASP | Managed | Block |
| SQL Injection Rule Set | Managed | Block |
| Rate limit >500 req/5min por IP | Custom | Block |

---

### 🖥️ Compute — `compute_ecs.tf` / `compute_beanstalk.tf`
| Servicio | Recurso | Uso |
|---|---|---|
| ECS Fargate | `steam-cluster` + `game-api` | API de videojuegos |
| Elastic Beanstalk | `steam-workers-prod` | Workers / procesos en segundo plano |

- ECS usa `LabRole` para ejecución (restricción AWS Academy)
- Beanstalk en modo `SingleInstance` para optimizar créditos
- El API Gateway actúa como proxy hacia Beanstalk

---

### 🗃️ Datos — `database_storage.tf`
| Recurso | Detalle |
|---|---|
| `aws_db_instance` (PostgreSQL 15) | `db.t3.micro` · 20 GB · cifrado KMS (`aws/rds`) |
| `aws_s3_bucket` | Almacenamiento privado de juegos y archivos |
| `aws_security_group` (db_sg) | Permite tráfico PostgreSQL (5432) |

---

### 📱 Frontend — `amplify.tf`
| Recurso | Detalle |
|---|---|
| `aws_amplify_app` | Conectado a GitHub, buildspec Vite |
| `aws_amplify_branch` | Rama configurada (por defecto `main`) · stage PRODUCTION |

**Variables de entorno inyectadas en build:**
| Variable | Valor |
|---|---|
| `VITE_AWS_USER_POOL_ID` | ID del User Pool de Cognito |
| `VITE_AWS_USER_POOL_CLIENT_ID` | ID del App Client de Cognito |
| `VITE_API_URL` | URL del API Gateway (stage `prod`) |

---

### 🌐 Networking & DNS — `network.tf`
| Recurso | Detalle |
|---|---|
| `aws_route53_zone` | Zona pública para el dominio personalizado |
| `aws_amplify_domain_association` | Conecta el dominio con la app de Amplify |
| `aws_route53_record` (www) | Registro CNAME para `www.dominio.com` |
| `aws_route53_record` (cert) | Registro CNAME para validación SSL de Amplify |

---

## 🚀 Instrucciones de despliegue

### Requisitos previos
- [Terraform](https://www.terraform.io/downloads) ≥ 1.3
- AWS CLI configurado con el **token de sesión de AWS Academy**
- GitHub Personal Access Token con permisos `repo` y `admin:repo_hook`

### 1. Configurar variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:

```hcl
aws_region                = "us-east-1"
lab_role_name             = "LabRole"
lab_instance_profile_name = "LabInstanceProfile"

github_repo_url = "https://github.com/TU_USUARIO/TU_REPO"
github_token    = "ghp_XXXXXXXXXXXXXXXXXXXXXXXX"
github_branch   = "main"
domain_name     = "tudominio.com"
```

### 2. Inicializar y desplegar

```bash
terraform init
terraform plan   # revisar qué se va a crear
terraform apply
```

### 3. Outputs tras el apply

```
cognito_user_pool_id        → ID del User Pool
cognito_app_client_id       → ID del App Client
cognito_hosted_ui_url       → URL de login
api_gateway_url             → VITE_API_URL del frontend
api_gateway_id              → ID del REST API
api_gateway_key             → (sensible) Clave de API
```

Para ver la API key:
```bash
terraform output -raw api_gateway_key
```

---

## ⚠️ Consideraciones AWS Academy

| Limitación | Solución aplicada |
|---|---|
| No se pueden crear roles IAM | Se usa el `LabRole` preexistente |
| KMS con claves propias bloqueado | Se usa la clave por defecto `aws/rds` |
| Amplify puede fallar si el repo no es accesible | Verificar que el token de GitHub tenga los permisos `repo` y `admin:repo_hook` |
| WAFv2 puede no estar disponible en Academy | Si falla, comentar el bloque `aws_wafv2_*` en `api_gateway.tf` |
| Las sesiones de Academy expiran | Renovar el token en `~/.aws/credentials` antes de cada `apply` |

---

## 🗂️ Estructura de ficheros

```
steamindio/
├── provider.tf              # Provider AWS + data sources
├── variables.tf             # Variables de entrada
├── terraform.tfvars.example # Plantilla de valores
├── auth.tf                  # Cognito User Pool + Client + Domain
├── api_gateway.tf           # API Gateway REST + WAF + Authorizer
├── amplify.tf               # Hosting frontend en Amplify
├── compute_ecs.tf           # ECS Cluster + Task Definition
├── compute_beanstalk.tf     # Elastic Beanstalk (workers)
├── database_storage.tf      # RDS PostgreSQL + S3 + Security Groups
├── network.tf               # Route 53 + Amplify Domain Association
└── outputs.tf               # Outputs de todos los recursos
```

---

## 📄 Licencia

Proyecto académico — uso educativo.
