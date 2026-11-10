# GOVERNANCE ACCOUNT 

# Due to the long time it took for me to create the AWS Architecture, I am only adding the main terraform components as I am running out of time. Please note that everyting is defined at a high level
# and this code is not production ready. Therefore, please do not try to deploy this. 

# Also all the architecture I have designed here are based on my own views and opinions.

resource "aws_dynamodb_table" "communications" {
  name         = "communication-approval-registry"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"
  attribute {
    name = "request_id"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
  }
}

resource "aws_s3_bucket" "approval_evidence" {
  bucket = var.unique_audit_bucket_name
}

resource "aws_s3_bucket_versioning" "approval_evidence" {
  bucket = aws_s3_bucket.approval_evidence.id
  versioning_configuration {
    status = "Enabled"
  }
  encryption              = true
}

# PSEUDOCODE for Step Functions with Lambda / authorized human approval:
# State machine:
#   ValidateRequest -> CheckIdentityAndRequestDigest -> WaitForHumanDecision
#   -> IfRejected: record REJECTED, notify, STOP
#   -> IfApproved: record APPROVED in DynamoDB, write S3 evidence
#   -> Send trusted approval to protected Shared Services Network Policy Pipeline
# Approval must be bound to account, source, destination, port/action, environment,
# Git commit/policy digest, approver ID and expiry. Security identity cannot be self-asserted.
# A separate S3 log archive in the Logging Account stores long-lived audit evidence.

variable "unique_audit_bucket_name" {
  type = string
}
