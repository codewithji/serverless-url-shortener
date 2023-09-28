provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      app         = var.aws_app_name
      environment = var.environment
    }
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# S3
# ---------------------------------------------------------------------------------------------------------------------

resource "random_pet" "lambda_bucket_name" {
  prefix = "${var.environment}-${var.aws_app_name}"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

data "archive_file" "lambda_shorten_url" {
  type = "zip"

  source_dir  = "${path.module}/lambdas/shorten-url"
  output_path = "${path.module}/shorten-url.zip"
}

data "archive_file" "lambda_redirect" {
  type = "zip"

  source_dir  = "${path.module}/lambdas/redirect"
  output_path = "${path.module}/redirect.zip"
}

resource "aws_s3_object" "lambda_shorten_url" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "shorten-url.zip"
  source = data.archive_file.lambda_shorten_url.output_path

  etag = filemd5(data.archive_file.lambda_shorten_url.output_path)
}

resource "aws_s3_object" "lambda_redirect" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "redirect.zip"
  source = data.archive_file.lambda_redirect.output_path

  etag = filemd5(data.archive_file.lambda_redirect.output_path)
}

# ---------------------------------------------------------------------------------------------------------------------
# Lambda functions
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_function" "shorten_url" {
  function_name = "${var.environment}_shorten_url"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_shorten_url.key

  runtime = "nodejs18.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda_shorten_url.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "${var.environment}_${var.dynamodb_table_name}"
      BASE_URL            = var.base_url
    }
  }
}

resource "aws_lambda_function" "redirect" {
  function_name = "${var.environment}_redirect_to_original_url"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_redirect.key

  runtime = "nodejs18.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda_redirect.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "${var.environment}_${var.dynamodb_table_name}"
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.environment}_serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# API Gateway
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "lambda" {
  name          = "${var.environment}_serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "${var.environment}_serverless_lambda"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 10
  }
}

resource "aws_apigatewayv2_integration" "shorten_url" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.shorten_url.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "redirect" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.redirect.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "shorten_url" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /shorten-url"
  target    = "integrations/${aws_apigatewayv2_integration.shorten_url.id}"
}

resource "aws_apigatewayv2_route" "redirect" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /{short_url_id}"
  target    = "integrations/${aws_apigatewayv2_integration.redirect.id}"
}

resource "aws_lambda_permission" "api_gw_shorten_url" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shorten_url.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_redirect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirect.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------------------------------------------------
# DynamoDB
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_dynamodb_table" "url_shortener_table" {
  name         = "${var.environment}_${var.dynamodb_table_name}"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Frontend (S3 & CloudFront)
# ---------------------------------------------------------------------------------------------------------------------

resource "random_pet" "frontend_bucket_name" {
  prefix = "${var.environment}-frontend"
  length = 4
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = random_pet.frontend_bucket_name.id
}

locals {
  mime_type_mappings = {
    html = "text/html",
    js   = "text/javascript",
    css  = "text/css",
    svg  = "image/svg+xml"
  }
}

resource "aws_s3_object" "frontend_build" {
  for_each     = fileset("${path.module}/frontend/dist", "**")
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = each.value
  source       = "${path.module}/frontend/dist/${each.value}"
  content_type = lookup(local.mime_type_mappings, concat(regexall("\\.([^\\.]*)$", each.value), [[""]])[0][0], "application/octet-stream")
  etag         = filemd5("${path.module}/frontend/dist/${each.value}")
}

resource "aws_cloudfront_origin_access_control" "cf_control" {
  name                              = aws_s3_bucket.frontend_bucket.id
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cf_control.id
    origin_id                = aws_s3_bucket.frontend_bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend_bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "random_pet" "cf_policy_name" {
  prefix = "cf-private-content-policy"
  length = 3
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version : "2008-10-17",
    Id : "${random_pet.cf_policy_name.id}",
    Statement : [
      {
        Sid : "",
        Effect : "Allow",
        Principal : {
          Service : "cloudfront.amazonaws.com"
        },
        Action : "s3:GetObject",
        Resource : "arn:aws:s3:::${aws_s3_bucket.frontend_bucket.id}/*",
        Condition : {
          StringEquals : {
            "AWS:SourceArn" : "${aws_cloudfront_distribution.cf_distribution.arn}"
          }
        }
      }
    ]
  })
}