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

resource "aws_amplify_domain_association" "main" {
  app_id      = aws_amplify_app.frontend.id
  domain_name = var.domain_name

  # No bloquear el apply esperando la verificación del cert;
  # la verificación se completará sola cuando los NS estén propagados.
  wait_for_verification = false

  # Dominio raíz (apex) → rama principal
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }

  # www.dominio.com → rama principal
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
}

# -------------------------------------------------------
# Route 53 — Registros CNAME para los subdominios de Amplify
# Amplify usa su propia CDN: <branch>.<app-id>.amplifyapp.com
# -------------------------------------------------------

# www.dominio.com → CDN de Amplify
resource "aws_route53_record" "amplify_www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.github_branch}.${aws_amplify_app.frontend.id}.amplifyapp.com"]
}

# -------------------------------------------------------
# Route 53 — Registro de verificación de certificado ACM
# Amplify genera este registro tras crear el domain_association.
# Lo construimos a partir del atributo certificate_verification_dns_record.
# Formato: "<name> CNAME <value>"
# -------------------------------------------------------

locals {
  # Separa "name CNAME value" en partes
  cert_record_parts = split(" ", aws_amplify_domain_association.main.certificate_verification_dns_record)
  cert_record_name  = length(local.cert_record_parts) >= 3 ? local.cert_record_parts[0] : ""
  cert_record_value = length(local.cert_record_parts) >= 3 ? local.cert_record_parts[2] : ""
}

resource "aws_route53_record" "amplify_cert_verification" {
  count   = local.cert_record_name != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = local.cert_record_name
  type    = "CNAME"
  ttl     = 300
  records = [local.cert_record_value]
}
