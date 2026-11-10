# SHARED SERVICES ACCOUNT 


# Here we host 2 different pipelines. One pipeline for deploying workload infrastructure and the other for deploying approved chnages from Governance or IT-Security Team.

# CodePipeline 1: WORKLOAD INFRASTRUCTURE PIPELINE
# GitHub source (connection) -> CodeBuild: TypeScript build, cdk synth, validate
# -> policy-impact classifier
# -> NO new communication: protected CloudFormation/CDK deployment role
# -> YES / ambiguous: stop automatic deployment, request for Governance (IT-Security) approval.

# CodePipeline 2: NETWORK POLICY PIPELINE
# Trusted, authenticated approved change request from Governance
# -> re-fetch approval in Governance (not from GitHub), verify request digest and expiry
# -> generate least-privilege policy change / terraform plan / CDK stack
# -> assume restricted Network + affected Workload account IAM roles
# -> apply approved rules and verify configuration -> log outcome.


# PSEUDOCODE for next steps: 
# - Create CodeConnections, 
# - Create two aws_codepipeline resources, 
# - Create the necessary IAM roles,
# - CodeBuild jobs, and necessary scripts and commands that we must run in the pipelines
# - Create artifacts bucket
# - Create KMS for encryption 
# - Perform guardrail checks, and cross-account deployments.

