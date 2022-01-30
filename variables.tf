variable "s3-buckets" {
  type    = map(string)
  default = {
      design = "cv-design-dev"
      display = "cv-display-dev"
  }
}
