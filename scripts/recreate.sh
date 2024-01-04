cd ./terraform

terraform init

terraform plan

trivy config \
    --tf-exclude-downloaded-modules   `# dont need to scan modules as downloaded to .terraform` \
    ./ \
    --debug

