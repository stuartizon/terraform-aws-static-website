output "bucket" {
  value       = aws_s3_bucket.website.bucket
  description = "The name of the website bucket"
}
