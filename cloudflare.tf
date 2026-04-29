# Automated DNS configuration in Cloudflare 
# to point to the AWS Route 53 Name Servers

resource "cloudflare_record" "aws_ns" {
  count   = 4
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  type    = "NS"
  content = aws_route53_zone.main.name_servers[count.index]
  ttl     = 1
}

# Example: Pointing a specific subdomain to the ECS/Beanstalk if needed
# resource "cloudflare_record" "api" {
#   zone_id = var.cloudflare_zone_id
#   name    = "api"
#   type    = "CNAME"
#   value   = aws_route53_zone.main.name # Internal AWS management
#   proxied = true
# }
