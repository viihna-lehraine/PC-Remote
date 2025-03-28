# File: vault/policies/pc-remote-service.hcl

# App runtime secrets
path "secret/data/pc-remote/session-secret" {
	capabilities = ["read"]
}

path "secret/data/pc-remote/pepper" {
	capabilities = ["read"]
}

# PKI cert issuance only for its own use
path "pki/intermediate/issue/backend" {
	capabilities = ["create", "update"]
}

# AppRole identity fetching (if AppRole is rotated often)
path "auth/approle/role/pc-remote-role/role-id" {
	capabilities = ["read"]
}

# DB credentials
path "postgresql/creds/viihna-app" {
	capabilities = ["read"]
}

path "auth/token/roles/*" {
  capabilities = ["create", "read"]
}
