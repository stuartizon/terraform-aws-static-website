# ACM certificates for use with CloudFront must be in US East 1
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  alias   = "us-east"
}

# Certificate for the domain name and any redirect urls
module "certificate" {
  source                    = "stuartizon/certificate/aws"
  version                   = "0.1.2"
  domain_name               = var.domain_name
  subject_alternative_names = var.redirects
  zone_id                   = var.zone_id

  providers = {
    aws = aws.us-east
  }
}

# Access policy so only CloudFront has access to the S3 bucket
resource "aws_cloudfront_origin_access_identity" "website" {
  comment = var.description
}

data "aws_iam_policy_document" "cloudfront_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.domain_name}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.website.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.domain_name}"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.website.iam_arn]
    }
  }
}

# S3 Bucket where the actual website content should go
resource "aws_s3_bucket" "website" {
  bucket = var.domain_name
  policy = data.aws_iam_policy_document.cloudfront_access.json
  tags   = var.tags

  website {
    index_document = var.index_page
  }
}

# CloudFront to serve the main domain name
resource "aws_cloudfront_distribution" "website" {
  comment             = var.description
  default_root_object = var.index_page
  tags                = var.tags
  aliases             = [var.domain_name]
  enabled             = true
  is_ipv6_enabled     = true

  origin {
    domain_name = aws_s3_bucket.website.bucket_domain_name
    origin_id   = var.domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = module.certificate.arn
    ssl_support_method  = "sni-only"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.index_page}"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    target_origin_id       = var.domain_name
    viewer_protocol_policy = "redirect-to-https"
    default_ttl            = 300

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
}

# DNS entry for the Cloud Front distribution
resource "aws_route53_record" "website" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# Redirection buckets
resource "aws_s3_bucket" "redirect" {
  count  = length(var.redirects)
  bucket = var.redirects[count.index]
  tags   = var.tags

  website {
    redirect_all_requests_to = "https://${var.domain_name}"
  }
}

# CloudFront distributions to serve the redirection URLs
resource "aws_cloudfront_distribution" "redirect" {
  count           = length(var.redirects)
  comment         = var.description
  tags            = var.tags
  aliases         = [var.redirects[count.index]]
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.redirect[count.index].website_endpoint
    origin_id   = var.redirects[count.index]

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = module.certificate.arn
    ssl_support_method  = "sni-only"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.redirects[count.index]
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
}

# DNS entries for the redirection distributions
resource "aws_route53_record" "redirect" {
  count   = length(var.redirects)
  zone_id = var.zone_id
  name    = var.redirects[count.index]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect[count.index].domain_name
    zone_id                = aws_cloudfront_distribution.redirect[count.index].hosted_zone_id
    evaluate_target_health = false
  }
}
