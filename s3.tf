resource "aws_s3_bucket" "app-buckets" {
  for_each = var.s3-buckets
  bucket = each.key
  acl    = "private"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  force_destroy = true
}