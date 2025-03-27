# File: vault/pc-remote-policy.hcl

path "auth/approle/role/pc-remote-role/role-id" {
  capabilities = ["read"]
}

path "auth/approle/role/pc-remote-role/secret-id" {
  capabilities = ["create", "read"]
}

path "postgresql/creds/viihna-app" {
	capabilities = ["read"]
}

path "database/creds/pc-remote-role" {
  capabilities = ["read"]
}

# Allow issuing certs for PKI
path "pki/intermediate/issue/*" {
	capabilities = ["create", "update"]
}

# Allow reading PKI roles
path "pki/intermediate/roles/*" {
	capabilities = ["read"]
}

# Allow reading CA info
path "pki/intermediate/cert/ca" {
  capabilities = ["read"]
}

# Allow cert revocation
path "pki/intermediate/revoke" {
  capabilities = ["update"]
}

path "secret/data/pc-remote/tls/*" {
  capabilities = ["read"]
}

path "secret/data/pc-remote/pepper" {
  capabilities = ["read"]
}

path "secret/data/pc-remote/session-secret" {
	capabilities = ["read"]
}
