# Download Terraform 1.6.1 (latest stable as of now)
curl -LO https://releases.hashicorp.com/terraform/1.6.1/terraform_1.6.1_linux_amd64.zip

# Unzip the binary
unzip terraform_1.6.1_linux_amd64.zip

# Move it to /usr/local/bin so it's globally accessible
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
