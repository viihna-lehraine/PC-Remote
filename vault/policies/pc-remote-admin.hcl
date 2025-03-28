# File: vault/pc-remote-admin.hcl

# Full access to your app's secrets
path "secret/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage AppRole config
path "auth/approle/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage PKI setup
path "pki/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage Postgres engine and roles
path "postgresql/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/token/roles/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
