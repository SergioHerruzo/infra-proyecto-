# -------------------------------------------------------
# API Gateway REST API (v1) - Con seguridad recomendada
# -------------------------------------------------------

resource "aws_api_gateway_rest_api" "main" {
  name        = "steam-indio-api"
  description = "API REST de Steam Indio con seguridad reforzada"

  # Desactiva el endpoint por defecto (solo acceso regional)
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # Habilita validación de body/parámetros a nivel de API
  minimum_compression_size = 1024

  tags = {
    Name    = "steam-indio-api"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# Cognito Authorizer
# -------------------------------------------------------

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.main.arn]

  # Token enviado en la cabecera Authorization
  identity_source = "method.request.header.Authorization"
}

# -------------------------------------------------------
# Request Validator (valida headers y query params)
# -------------------------------------------------------

resource "aws_api_gateway_request_validator" "main" {
  name                        = "validate-request"
  rest_api_id                 = aws_api_gateway_rest_api.main.id
  validate_request_body       = true
  validate_request_parameters = true
}

# -------------------------------------------------------
# Resources - /health (público) y /{proxy+} (protegido)
# -------------------------------------------------------

# /{proxy+}
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}


# -------------------------------------------------------
# Methods
# -------------------------------------------------------

# ANY /{proxy+} — requiere token Cognito
resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_validator_id = aws_api_gateway_request_validator.main.id

  request_parameters = {
    "method.request.header.Authorization" = true
    "method.request.path.proxy"           = true
  }
}

# -------------------------------------------------------
# Integrations
# -------------------------------------------------------

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_elastic_beanstalk_environment.prod.cname}/{proxy}"

  cache_key_parameters = ["method.request.path.proxy"]

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# -------------------------------------------------------
# Deployment & Stage
# -------------------------------------------------------

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Fuerza re-deploy al cambiar recursos o métodos
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_integration.proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.proxy,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"

  # X-Ray tracing activo
  xray_tracing_enabled = true

  # Access logging a CloudWatch
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "steam-indio-api-prod"
  }
}

# -------------------------------------------------------
# Method Settings (logging + throttling por stage)
# -------------------------------------------------------

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    # Logging
    logging_level          = "INFO"
    data_trace_enabled     = false # true solo en desarrollo
    metrics_enabled        = true

    # Throttling por método (ajusta según necesidad)
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}

# -------------------------------------------------------
# Usage Plan + API Key (capa extra de control de acceso)
# -------------------------------------------------------

resource "aws_api_gateway_api_key" "frontend" {
  name        = "steam-frontend-key"
  description = "Clave de API para el frontend de Steam Indio"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "main" {
  name        = "steam-usage-plan"
  description = "Plan de uso estándar para Steam Indio"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  # Límite total mensual de peticiones
  quota_settings {
    limit  = 100000
    period = "MONTH"
  }

  # Throttling global del plan
  throttle_settings {
    burst_limit = 200
    rate_limit  = 100
  }
}

resource "aws_api_gateway_usage_plan_key" "frontend" {
  key_id        = aws_api_gateway_api_key.frontend.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}

# -------------------------------------------------------
# WAFv2 - Web Application Firewall (seguridad perimetral)
# -------------------------------------------------------

resource "aws_wafv2_web_acl" "api_gw" {
  name        = "steam-api-waf"
  description = "WAF para API Gateway de Steam Indio"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Regla 1: Protección contra IPs maliciosas conocidas de AWS
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # Regla 2: Reglas comunes de OWASP (SQLi, XSS, etc.)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Regla 3: Protección contra SQL Injection conocido
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Regla 4: Rate limiting — bloquea más de 500 req/5min por IP
  rule {
    name     = "RateLimitPerIP"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "steam-api-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name    = "steam-api-waf"
    Project = "steam-indio"
  }
}

# Asocia el WAF con el stage de API Gateway
resource "aws_wafv2_web_acl_association" "api_gw" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.api_gw.arn
}

# -------------------------------------------------------
# CloudWatch Log Groups
# -------------------------------------------------------

resource "aws_cloudwatch_log_group" "api_gw_access" {
  name              = "/aws/apigateway/steam-indio/access"
  retention_in_days = 30

  tags = {
    Name = "steam-api-access-logs"
  }
}

resource "aws_cloudwatch_log_group" "api_gw_exec" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/prod"
  retention_in_days = 14

  tags = {
    Name = "steam-api-exec-logs"
  }
}
