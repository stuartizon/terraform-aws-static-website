# Terraform AWS Static Website
Terraform module which creates all the resources you'll need to run a static website with AWS S3 and CloudFront.

Static Website Generators are more popular than ever, but deploying everything you need to run a static website on AWS can be challenging to the uninitiated and it's easy to forget some of the details even if you've done this sort of thing many times before. That's where this module comes in.

The module sets up for you:
- an S3 bucket to put your web resources into
- a CloudFront distribution to serve traffic to the bucket
- a DNS entry for the CloudFront distribution
- an ACM certificate to encrypt the traffic
- any number of redirects (e.g. redirect all traffic from `example.com` to `www.example.com`)

Once this infrastructure is built, you can use any tool to drop files into the main S3 bucket, and the content will sync up to the CloudFront distribution.

## Usage
```hcl
module "website" {
  source = "stuartizon/static-website/aws"
  version = "~> 0.1.0"
  domain_name = "www.example.com"
  zone_id = "ZAAAAAAAAAAAAA"
  redirects = ["example.com"]
}
```

## Variables
| Name | Type | Description | Default |
|------|------|-------------|---------|
| domain_name | `string` | The main domain name of the website | |
| zone_id | `string` | The ID of the Route 53 hosted zone corresponding to the top level domain name | |
| redirects | `list(string)` | A list of alternate domains to redirect to the main domain | `[]` |
| description | `string` | An optional description for the website resources | `""` |
| index_page | `string` | The index page for the site | `index.html` |
| tags | `map` | A map of tags to assign to the resources | `{}` |

## Outputs
| Name | Description |
|------|-------------|
| bucket_id | The id of the website bucket |
| bucket_arn | The ARN of the website bucket |
| bucket_domain_name | The domain name of the website bucket |

## Providers and Regions
[To use ACM certificates with CloudFront](https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html) they must be requested in the `us-east-1` region. To that end this module declares a provider for the us-east-1 region, specifically for the ACM certificate. This assumes that the [authentication mechanism](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) is via environment variables. Passing in credentials via other mechanisms may require a change in approach.

All other resources assume an AWS provider is defined (or explicitly set in the module arguments) for whichever region the rest of these resources should be deployed to.

Note that this is a [legacy behaviour](https://www.terraform.io/docs/configuration/modules.html) which has an impact on how the Terraform state is handled.