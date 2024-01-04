# trivy_recreate

run  `bash scripts/recreate.sh` from root

### Overview

Example to recreate bug encountered when using trivy v0.48.1. Specifically an issue with the `misconfiguartion` scanner, when using terraform with AWS there is a discrepancy between how trivy behaves when a modules source is downloaded vs local.


For example, we have a terraform module where there is a misconfiguation which is correctly identified using trivy and is flagged. If we load this module via a local file path and then address the misconfiguration, trivy correctly identifys its been resolved  and stops flagging it. However if the same module is downloaded and then the misconfiguration is resolved in the same, trivy incorrectly throws an error.


### Example

The module we are importing is a basic vpc, `terraform/modules/vpc`.

```
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}
output "vpc_id" {
  value = aws_vpc.vpc.id
}
```

This vpc has no flow logs enabled and thus when used alone and scanned using trivy this should throw the failure for `avd-aws-0178`, this is flag expected. 
```
// Create vpc from local module without flow logs as a control
module "vpc_created_from_local_module_without_flow_logs" {
  source = "./modules/vpc"
}
```


To resolve, after importing the module we create the neccesary flow logs resources and pair them to the imported local module and thus when we rerun trivy the errors are no longer present because trivy has correctly detected that the vpc has flow logs enabled.
```
// Create vpc from local module with flow logs
module "vpc_created_from_local_module_with_flow_logs" {
  source = "./modules/vpc"
}
resource "aws_flow_log" "flow_logs_to_local_module" {
  iam_role_arn    = aws_iam_role.example.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc_created_from_local_module_with_flow_logs.vpc_id
}
// other required resources for flow logs ...
```

However when recreating this step using a downloaded module, trivy does not detect that the flow logs have been enabled for the downloaded module and throws thus it fails the test, this is not expected behaviour as the flow logs have been enabled, and the only difference here is the origin location of the module. Additionally the `trivy:ignore` statement has no effect whatsoever and the errors are still thrown.

```
// Create vpc from downloaded module with flow logs
#trivy:ignore:avd-aws-0178
module "vpc_created_from_downloaded_module" {
  source = "github.com/Liambeck99/trivy_recreate.git//terraform/modules/vpc"
}
resource "aws_flow_log" "flow_logs_to_downloaded_module" {
  iam_role_arn    = aws_iam_role.example.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc_created_from_downloaded_module.vpc_id
}
// other required resources for flow logs ...
```

The trivy output can be seen here, showing the control module, the local import with VPC logs enabled is not present as expected and the downloaded module is incorrectly flagged as the vpc logs have actually been enabled :

![image](https://github.com/Liambeck99/trivy_recreate/assets/57397563/b482d8ea-7c26-4355-b942-8199a244c200)

We can verify the logs have been enabled as they are present in the terraform plan :

![image](https://github.com/Liambeck99/trivy_recreate/assets/57397563/89b074fd-9e5e-4d4b-b5a0-059d6bf8d2e8)