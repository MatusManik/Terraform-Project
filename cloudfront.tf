# AWS CloudFront Global Content Delivery Network (CDN)

# Creates a CloudFront distribution to cache and serve web content closer to users globally
resource "aws_cloudfront_distribution" "web_distribution" {

  enabled = true
  comment = "CloudFront distribution for the web application"

  # ORIGIN CONFIGURATION
  # Specifies where CloudFront fetches the original content from (Application Load Balancer)
  origin {
    domain_name = aws_lb.web_application_load_balancer.dns_name
    origin_id   = "application-load-balancer" # Unique identifier for this origin within the distribution

    # Connection settings between CloudFront edge locations and the backend Load Balancer
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # Strictly force encrypted HTTPS connections to the backend

      # Use modern, secure TLS protocols for edge-to-origin backend communication
      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  # DEFAULT CACHE BEHAVIOR
  # Controls how CloudFront handles incoming user HTTP requests and caching logic
  default_cache_behavior {
    target_origin_id = "application-load-balancer"

    # Security: Automatically redirect all HTTP requests from clients to HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # Allowed HTTP methods that CloudFront will accept and forward
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    # HTTP methods that CloudFront will cache responses for
    cached_methods = [
      "GET",
      "HEAD"
    ]

    # Enable automatic file compression (Gzip/Brotli) to speed up download times for end-users
    compress = true

    # Forwarding configuration: Controls how queries and cookies affect cache key generation
    forwarded_values {
      query_string = false # Ignore URL query parameters when caching content

      cookies {
        forward = "none" # Do not forward cookies to origin to maximize cache hit ratio
      }
    }
  }

  # COST & LOCATION STRATEGY
  # PriceClass_100 uses only the lowest-cost edge locations (North America & Europe) to minimize AWS costs
  price_class = "PriceClass_100"

  # GEOGRAPHIC RESTRICTIONS
  # Allows or blocks traffic based on country origin (set to allow all)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS CERTIFICATE CONFIGURATION
  # Uses the default fallback *.cloudfront.net SSL certificate provided by AWS
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}