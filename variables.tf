variable "domain_name" {
  type        = string
  description = "The main domain of the website e.g. www.example.com"
}

variable "redirects" {
  type        = list(string)
  default     = []
  description = "Alternate domains to redirect to the main domain e.g. example.com"
}

variable "zone_id" {
  type        = string
  description = "The ID of the Route53 hosted zone corresponding to the top level domain name"
}

variable "description" {
  type        = string
  default     = ""
  description = "An optional description for the website resources"
}

variable "index_page" {
  type        = string
  default     = "index.html"
  description = "Index page for your site, e.g: index.html"
}

variable "tags" {
  type        = map
  description = "A map of tags to assign to resources"
  default     = {}
}
