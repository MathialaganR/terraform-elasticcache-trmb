# Define composite variables for resources
module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.5.3"
  enabled    = "${var.enabled}"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

#
# Security Group Resources
#
resource "aws_security_group" "default" {
  count  = "${var.enabled == "true" ? 1 : 0}"
  vpc_id = "${var.vpc_id}"
  name   = "${module.label.id}"

  ingress {
    from_port       = "${var.port}"              # Redis
    to_port         = "${var.port}"
    protocol        = "tcp"
    security_groups = ["${var.security_groups}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${module.label.tags}"
}

locals {
  elasticache_subnet_group_name = "${var.elasticache_subnet_group_name != "" ? var.elasticache_subnet_group_name : join("", aws_elasticache_subnet_group.default.*.name) }"
}

resource "aws_elasticache_subnet_group" "default" {
  count      = "${var.enabled == "true" && var.elasticache_subnet_group_name == "" && length(var.subnets) > 0 ? 1 : 0}"
  name       = "${module.label.id}"
  subnet_ids = ["${var.subnets}"]
}

resource "aws_elasticache_parameter_group" "default" {
  count     = "${var.enabled == "true" ? 1 : 0}"
  name      = "${module.label.id}"
  family    = "${var.family}"
  parameter = "${var.parameter}"
}

resource "aws_elasticache_replication_group" "default" {
  count = "${var.enabled == "true" ? 1 : 0}"

  auth_token                    = "${var.auth_token}"
  replication_group_id          = "${var.replication_group_id == "" ? module.label.id : var.replication_group_id}"
  replication_group_description = "${module.label.id}"
  node_type                     = "${var.instance_type}"
  number_cache_clusters         = "${var.cluster_size}"
  port                          = "${var.port}"
  parameter_group_name          = "${aws_elasticache_parameter_group.default.name}"
  availability_zones            = ["${slice(var.availability_zones, 0, var.cluster_size)}"]
  automatic_failover_enabled    = "${var.automatic_failover}"
  subnet_group_name             = "${local.elasticache_subnet_group_name}"
  security_group_ids            = ["${aws_security_group.default.id}"]
  maintenance_window            = "${var.maintenance_window}"
  notification_topic_arn        = "${var.notification_topic_arn}"
  engine_version                = "${var.engine_version}"
  at_rest_encryption_enabled    = "${var.at_rest_encryption_enabled}"
  transit_encryption_enabled    = "${var.transit_encryption_enabled}"
  snapshot_window               = "${var.snapshot_window}"
  snapshot_retention_limit      = "${var.snapshot_retention_limit}"

  tags = "${module.label.tags}"
}