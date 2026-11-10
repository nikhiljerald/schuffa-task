# LOGGING ACCOUNT 

# I am creating only one bucket here. However, ideally we must create multiple buckets to store all kind of logs. 
# We can have seperate buckets for CloudTrailLogs, Cloud Trail Logs, Transit Gateway Logs, Network Firewall Logs, VPC Flow Logs, S3 Audit Logs, S3 Access Logs, ALB/NLB Access Logs etc.. 
# All the buckets should have encryption enabled, and public access blocked

resource "aws_s3_bucket" "network_logs" {
  bucket = var.unique_network_logs_bucket
}
resource "aws_s3_bucket_public_access_block" "network_logs" {
  bucket                  = aws_s3_bucket.network_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  encryption              = true
}

# PSEUDOCODE for other Logs Storage buckets:
# - Create 2 Buckets for Organization CloudWatch and CloudTrail (including selected DynamoDB/S3 data events)
# - Create 4 Buckets for TGW Logs, VPC flow logs, Network Firewall alert/flow logs, API Gateway access logs
# - Create S3 secure delivery policies, bucket policies, KMS keys for encryption, enable retention/versioning/Object Lock where required, and block public bucket access
# - Use Athena for queries: approved vs deployed vs observed connectivity

variable "unique_network_logs_bucket" {
  type = string
}
