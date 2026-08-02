# AWS Route 53 DNS Configuration

# Create a primary Managed Public Route 53 Hosted Zone for the domain.
resource "aws_route53_zone" "web_application_zone" {
  name = "mywebsite.com"
}

# Create an Alias "A" Record mapping the subdomain directly to an AWS CloudFront Distribution.
resource "aws_route53_record" "web_application_record" {

  zone_id = aws_route53_zone.web_application_zone.id
  name    = "www.mywebsite.com"
  type    = "A"

  alias {
    # Dynamically retrieves the CloudFront domain name (e.g., d111111abcdef8.cloudfront.net)
    name = aws_cloudfront_distribution.web_distribution.domain_name
    
    # CloudFront distributions always use a static Hosted Zone ID managed by AWS
    zone_id = aws_cloudfront_distribution.web_distribution.hosted_zone_id
    
    # Health checks evaluation: Set to 'false' because CloudFront automatically handles 
    # distribution health and edge location failover globally.
    evaluate_target_health = false
  }
}