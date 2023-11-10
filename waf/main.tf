resource "aws_wafv2_ip_set" "vpn_ips" {
  name               = "vpn_ips"
  description        = "VPN IPs"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["x.x.x.x/x", "x.x.x.x/x", "x.x.x.x/x"]
}

resource "aws_wafv2_web_acl" "yarno-acl" {
  name        = "exampleACL"
  description = "Primary example Web ACL"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "allow-vpn-traffic"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = "${aws_wafv2_ip_set.vpn_ips.arn}"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-access"
      sampled_requests_enabled   = true
    }
  }


  rule {
    name     = "example-to-non-vpn-traffic"
    priority = 5

    action {
      block {}
    }

    statement {
			byte_match_statement {
				field_to_match {
					single_header {
						name = "host"
					}
				}
				positional_constraint = "STARTS_WITH"
				search_string = "example.com.au"
				text_transformation {
					priority = 1
					type = "LOWERCASE"
				}
			}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-access"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "acl-association" {
  resource_arn = aws_alb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.yarno-acl.arn
}
