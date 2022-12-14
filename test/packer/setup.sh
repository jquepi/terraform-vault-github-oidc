#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Install Vault
apt-get -o DPkg::Lock::Timeout=60 install -y gpg at
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
[ "$(gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint | head -n 4 | tail -n 1 | xargs)" = "E8A0 32E0 94D8 EB4E A189 D270 DA41 8C88 A321 9F7B" ]
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get -o DPkg::Lock::Timeout=60 update
apt-get -o DPkg::Lock::Timeout=60 -y install vault
vault --version

# Mkcert
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
echo "mkcert version:" "$(mkcert -version)"
mkcert -install
# This is going to set the wrong IP address given Terraform will generate a
# Droplet with a different IP address, but whatever.
# We skip TLS verification anyway.
IPV4_ADDRESS="$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)"
mkcert "${IPV4_ADDRESS}" localhost 127.0.0.1 ::1
mv "${IPV4_ADDRESS}"*-key.pem /root/vault-key.pem
mv "${IPV4_ADDRESS}"*.pem /root/vault.pem

# Configure Vault for CI testing
echo '
storage "inmem" {}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_cert_file = "/root/vault.pem"
  tls_key_file = "/root/vault-key.pem"
}

ui = true
disable_mlock = true
' > vault-config.hcl
