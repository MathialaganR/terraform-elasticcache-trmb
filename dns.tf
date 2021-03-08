resource "aws_route53_record" "default" {
  count   = "${var.route53_required ? 1 : 0}"
  name    = "${var.elasticache_route53}"
  zone_id = "${var.global_phz_id}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_elasticache_replication_group.default.primary_endpoint_address}"]
}