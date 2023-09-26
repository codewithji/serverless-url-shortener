output "base_url" {
  description = "Base URL for API Gateway"
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}
