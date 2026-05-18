# -------------------------------------------------------
# Route 53 — Hosted Zone pública
# -------------------------------------------------------

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Zona pública de Steam Indio — ${var.domain_name}"

  tags = {
    Name    = "steam-indio-zone"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# Amplify — Asociación de dominio personalizado
# Amplify emitirá un certificado ACM y lo validará
# automáticamente en cuanto los NS apunten a esta zona.
# -------------------------------------------------------

# -------------------------------------------------------
# Amplify - Asociación de dominio para PROD (apex + www)
# -------------------------------------------------------

resource "aws_amplify_domain_association" "prod" {
  app_id      = aws_amplify_app.prod.id
  domain_name = var.domain_name

  wait_for_verification = false

  # Dominio raíz (apex) -> rama principal
  sub_domain {
    branch_name = aws_amplify_branch.prod_main.branch_name
    prefix      = ""
  }

  # www.dominio.com -> rama principal
  sub_domain {
    branch_name = aws_amplify_branch.prod_main.branch_name
    prefix      = "www"
  }
}

# -------------------------------------------------------
# Amplify - Asociación de dominio para DEV (dev subdomain)
# -------------------------------------------------------

resource "aws_amplify_domain_association" "dev" {
  app_id      = aws_amplify_app.dev.id
  domain_name = var.domain_name

  wait_for_verification = false

  # dev.dominio.com -> rama principal de dev
  sub_domain {
    branch_name = aws_amplify_branch.dev_main.branch_name
    prefix      = "dev"
  }
}

# -------------------------------------------------------
# Route 53 — Registros CNAME para los subdominios de Amplify
# -------------------------------------------------------

# www.dominio.com → CDN de Amplify PROD
resource "aws_route53_record" "amplify_www" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = "www.${var.domain_name}"
  type            = "CNAME"
  ttl             = 300
  records         = ["${var.github_branch}.${aws_amplify_app.prod.id}.amplifyapp.com"]
  allow_overwrite = true
}

# dev.dominio.com → CDN de Amplify DEV
resource "aws_route53_record" "amplify_dev" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = "dev.${var.domain_name}"
  type            = "CNAME"
  ttl             = 300
  records         = ["${var.github_branch_dev}.${aws_amplify_app.dev.id}.amplifyapp.com"]
  allow_overwrite = true
}

# -------------------------------------------------------
# Route 53 — Registros de verificación de certificado ACM
# -------------------------------------------------------

locals {
  # Verificación PROD
  cert_prod_parts = split(" ", aws_amplify_domain_association.prod.certificate_verification_dns_record)
  cert_prod_name  = length(local.cert_prod_parts) >= 3 ? local.cert_prod_parts[0] : ""
  cert_prod_value = length(local.cert_prod_parts) >= 3 ? local.cert_prod_parts[2] : ""

  # Verificación DEV
  cert_dev_parts = split(" ", aws_amplify_domain_association.dev.certificate_verification_dns_record)
  cert_dev_name  = length(local.cert_dev_parts) >= 3 ? local.cert_dev_parts[0] : ""
  cert_dev_value = length(local.cert_dev_parts) >= 3 ? local.cert_dev_parts[2] : ""
}

resource "aws_route53_record" "amplify_prod_verification" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = local.cert_prod_name
  type            = "CNAME"
  ttl             = 300
  records         = [local.cert_prod_value]
  allow_overwrite = true
}

resource "aws_route53_record" "amplify_dev_verification" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = local.cert_dev_name
  type            = "CNAME"
  ttl             = 300
  records         = [local.cert_dev_value]
  allow_overwrite = true
}
