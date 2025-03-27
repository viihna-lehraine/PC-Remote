# File: vault/config.hcl

storage "file" {
  path					= "/vault/data"
}

listener "tcp" {
  address				= "0.0.0.0:4425"
  cluster_address		= "0.0.0.0:4426"
  tls_disable			= "0"
  tls_cert_file			= "/vault/certs/vault/vault.fullchain.crt"
  tls_key_file 			= "/vault/certs/vault/vault.key"
  tls_client_ca_file	= "/vault/ca/root/rootCA.crt"
}

api_addr				= "https://192.168.50.10:4425"
disable_mlock			= true
ui						= true
