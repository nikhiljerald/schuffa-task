# PER-WORKLOAD ACCOUNT 

# Please note again, that I am not writing the production-ready terraform code. I am writing only high-level code. 
# We must apply the same pattern separately to Workload A and Workload B in DEV, TEST and PROD environments/Accounts

resource "aws_ec2_transit_gateway_vpc_attachment" "workload" {
  vpc_id             = var.vpc_id
  subnet_ids         = var.tgw_attachment_subnet_ids
  transit_gateway_id = var.shared_tgw_id
  # Network Account owns association/propagation, including inspection routes.
}

# S3 and DynamoDB gateway endpoints live inside EACH using VPC
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.application_private_route_table_ids
  
  # PSEUDOCODE for next steps
  # - attach an approved restrictive VPC endpoint policy.
}
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.application_private_route_table_ids
  
  # PSEUDOCODE for next steps
  # - attach approved actions,
  # - attatch resource ARNs, 
  # - attach complementary IAM policy.
}

# I am creating an VPC Endpoint for Scenario 1 i.e integration of Workload A with PRIVATE REST API PATH which is inside Workload B -
# Workload A -> TGW -> Network Firewall -> TGW -> Workload B Interface VPC Endpoint -> private API.
# Route/DNS/NACL/SG must support A CIDRs; API resource policy must allow this VPCE ID.
resource "aws_vpc_endpoint" "private_api" {
  count               = var.host_execute_api_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = false # Explicit private DNS plan avoids public-API interference
  subnet_ids          = var.endpoint_private_subnet_ids
  security_group_ids  = [var.approved_endpoint_security_group_id]
}

# PSEUDOCODE for next steps: 
# - restrictive SGs on applications/ALB/NLB; 
# - Attatch necessary IAM actions
# - Implement an Authentication and Authorisation for any publically accesible API 
# - cross-account private REST API resource policy with aws:SourceVpce;
# - public API Gateway authorizer/resource policy; 
# - VPC subnet routes to TGW;
# - deployment role can change only delegated resources after Security approval.

variable "region" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "shared_tgw_id" {
  type = string
}
variable "tgw_attachment_subnet_ids" {
  type = list(string)
}
variable "application_private_route_table_ids" {
  type = list(string)
}
variable "host_execute_api_endpoint" {
  type = bool
  default = false
}
variable "endpoint_private_subnet_ids" {
  type = list(string)
  default = []
}
variable "approved_endpoint_security_group_id" {
  type = string
  default = ""
}
