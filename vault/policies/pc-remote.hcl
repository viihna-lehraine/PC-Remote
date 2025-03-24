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

path "secret/data/pc-remote/tls/*" {
  capabilities = ["read"]
}

path "secret/data/pc-remote/pepper" {
  capabilities = ["read"]
}

path "secret/data/pc-remote/session-secret" {
	capabilities = ["read"]
}
