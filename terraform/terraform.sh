# Download latest Terraform for Linux
curl -LO https://releases.hashicorp.com/terraform/1.13.3/terraform_1.13.3_linux_amd64.zip

# Unzip it
unzip terraform_1.13.3_linux_amd64.zip

# Move binary to /usr/local/bin
sudo mv terraform /usr/local/bin/

# Check version
terraform version
