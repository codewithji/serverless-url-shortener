variable "aws_region" {
  type = string
}

variable "aws_app_name" {
  type = string
}

variable "base_url" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "cf_domain_name" {
  type = string
}

variable "environment" {
  description = "This is the environment where my app is deployed"
  type        = string
}