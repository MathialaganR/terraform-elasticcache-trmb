resource "aws_route53_record" "main_elasticache" {
  count   = "${var.route53_required ? 1 : 0}"
  zone_id = "${var.global_phz_id}"
  name    = "${var.elasticache_route53}"
  type    = "A"

  alias {
    name                   = "${aws_elasticache_replication_group.default.primary_endpoint_address}"
    zone_id                = "${var.global_phz_id}"
    evaluate_target_health = true
  }
}
