output "bucket_id" {
  value       = aws_s3_bucket.website.id
  description = "The id of the website bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "The ARN of the website bucket e.g. arn:aws:s3:::www.example.com"
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.website.bucket_domain_name
  description = "The domain name of the website bucket e.g. www.example.com.s3.amazonaws.com"
}
