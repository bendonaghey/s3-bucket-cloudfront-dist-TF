resource "aws_cloudfront_origin_access_identity" "cv-oai" {
  for_each = var.s3-buckets
  comment = "OAI"
}

data "aws_iam_policy_document" "s3_policy" {
  for_each = var.s3-buckets
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app-buckets[each.key].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.cv-oai[each.key].iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.app-buckets[each.key].arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.cv-oai[each.key].iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "cv-app-buckets-policy" {
  for_each = var.s3-buckets
  bucket = aws_s3_bucket.app-buckets[each.key].id
  policy = data.aws_iam_policy_document.s3_policy[each.key].json
}

resource "aws_cloudfront_distribution" "s3_distribution-design" {
  for_each = var.s3-buckets
  depends_on = [
    aws_s3_bucket.app-buckets,
    aws_s3_bucket_policy.cv-app-buckets-policy
  ]

  origin {
    domain_name = aws_s3_bucket.app-buckets[each.key].bucket_regional_domain_name
    origin_id   = "${aws_s3_bucket.app-buckets[each.key].id}.s3.eu-west-2.amazonaws.com"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cv-oai[each.key].cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.app-buckets[each.key].id}.s3.eu-west-2.amazonaws.com"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }


  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  price_class = "PriceClass_200"

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}