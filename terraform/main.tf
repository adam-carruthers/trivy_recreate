// allow terraform plan to run without AWS credentials
provider "aws" {
  region                      = "eu-west-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

module "vpc_created_from_downloaded_module" {
  source = "github.com/Liambeck99/trivy_recreate.git//terraform/modules/vpc"
}

resource "aws_vpc" "vpc_created_from_local_resource" {
  cidr_block = "10.0.0.0/16"
}


// Simple VPC Flow Logs
// Example from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log

// Connect flow logs to vpc_created_from_downloaded_module
resource "aws_flow_log" "flow_logs_to_downloaded_module" {
  iam_role_arn    = aws_iam_role.example.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc_created_from_downloaded_module.vpc_id
}

// Connect flow logs to vpc_created_from_local_resource
resource "aws_flow_log" "flow_logs_to_local_resource" {
  iam_role_arn    = aws_iam_role.example.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc_created_from_local_resource.id
}

#trivy:ignore-reason:exception is irrelevant so can be ignored 
#trivy:ignore:avd-aws-0017
resource "aws_cloudwatch_log_group" "example" {
  name = "example"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

#trivy:ignore-reason:exception is irrelevant so can be ignored 
#trivy:ignore:avd-aws-0057
data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "example" {
  name   = "example"
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json
}
