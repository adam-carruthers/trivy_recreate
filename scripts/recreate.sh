cd ./terraform

terraform init

terraform plan # verify only trying to create single vpc

trivy config --tf-exclude-downloaded-modules --skip-dirs "modules" ./