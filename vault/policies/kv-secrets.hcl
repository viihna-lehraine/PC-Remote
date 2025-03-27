# File: vault/kv-secrets.hcl

path "secret/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}
