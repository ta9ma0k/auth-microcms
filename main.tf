terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }
}

resource "aws_apigatewayv2_api" "main" {
  name = "MicrocmsProxy"
  protocol_type = "HTTP" 
}

resource "aws_apigatewayv2_stage" "main" {
  api_id = aws_apigatewayv2_api.main.id
  name   = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "main" {
  api_id = aws_apigatewayv2_api.main.id 
  connection_type = "INTERNET"
  integration_type = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri = "https://8xsff0n0o4.microcms.io/api/v1/{proxy}"
  description = "MicrocmsのブログAPIへプロキシする"
  request_parameters = {
      "append:header.X-MICROCMS-API-KEY" : var.microcms_api_key
  }
}

resource "aws_apigatewayv2_authorizer" "azure_ad" {
  api_id = aws_apigatewayv2_api.main.id 
  name = "AzureAD"
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    issuer = "https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0"
    audience = ["${var.azure_app_id}"]
  }
}

resource "aws_apigatewayv2_route" "main" {
 api_id = aws_apigatewayv2_api.main.id 
 route_key = "GET /api/contents/{proxy+}"
 target = "integrations/${aws_apigatewayv2_integration.main.id}"
 authorization_type = "JWT"
 authorizer_id = aws_apigatewayv2_authorizer.azure_ad.id
}

