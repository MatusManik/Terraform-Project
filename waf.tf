# AWS WAFv2 (Web Application Firewall) Configuration

# Defines a Regional Web Application Firewall (WAF) Web ACL to protect resources
# against common web exploits and vulnerabilities.
resource "aws_wafv2_web_acl" "web_application_firewall" {
  name  = "Web-Application-Firewall"
  scope = "REGIONAL" # Apply to regional resources (e.g., Application Load Balancers, API Gateways)

  # Fallback rule: Allow traffic by default if no blocking rules are matched.
  default_action {
    allow {}
  }

  # Rule Definition: Managed Rule Group provided directly by AWS
  rule {
    name     = "AWSManagedCommonRules"
    priority = 1 # Lower numbers indicate higher evaluation priority

    # Keep the default block/allow actions configured by AWS within this rule group
    override_action {
      none {}
    }

    # Reference to the AWS-maintained rule set for common web vulnerabilities
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    # Metrics configuration for this specific rule
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRules"
      sampled_requests_enabled   = true
    }
  }

  # Overall CloudWatch visibility and metrics configuration for the entire Web ACL
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebApplicationFirewall"
    sampled_requests_enabled   = true
  }
}

# WAF Association
# Connects (attaches) the WAF Web ACL directly to the Application Load Balancer (ALB)
resource "aws_wafv2_web_acl_association" "web_application_firewall_association" {
  resource_arn = aws_lb.web_application_load_balancer.arn
  web_acl_arn  = aws_wafv2_web_acl.web_application_firewall.arn
}