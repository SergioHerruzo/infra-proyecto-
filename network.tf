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


