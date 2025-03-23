# 🔐 Vault Initialization & Setup Documentation (PC Remote)

---

## 📦 Vault Docker Container Overview

Vault runs inside a dedicated Docker container with:

-   Custom TLS config

-   Pre-mounted certs

-   Configured policies

-   Postgres dynamic secrets integration

All Vault setup is manual post-docker compose up (for now).

---

---

## Setup Flow Summary

### 1. Bring Up the Stack

-   `docker compose up -d`

-   This starts Vault sealed, with no initialized secrets engine or policies applied yet.

### 2. Unseal Vault

-   Run the unsealing script manually:

-   `sudo ./scripts/init_vault.sh`

This does the following:

-   #### 1. 🔐 Decrypts /home/viihna/Projects/pc-remote/.sops/usk.json.gpg (if needed)

-   #### 2. 🔑 Applies all unseal keys (from decrypted usk.json)

-   #### 3. Shreds the plaintext file after unsealing

-   #### 4. Runs the containerized /vault/init/configure.sh to configure the Vault instance

**_Vault must be fully unsealed before any secrets engines or policies can be written._**

---

---

### 3. Vault Entry Configuration (/vault/init/configure.sh)

This script runs inside the Vault container after unseal:

Applies the kv-secrets policy (loaded from /vault/policies/kv-secrets.hcl)

Enables the PostgreSQL secrets engine (if not already enabled)

Configures the Postgres plugin

Writes the viihna-app role for dynamic DB credential issuance

---

---

### 4. 📁 Important Files & Their Roles

-   #### File: `vault/init/entrypoint.sh`

    #### Purpose: Runs before Vault starts to prepare CA certs and base policy

-   #### File: `vault/init/configure.sh`

    #### Purpose: Configures DB secrets engine, roles, policies (run post-unseal)

-   #### File: `scripts/init_vault.sh`

    #### Purpose: Host script to decrypt unseal keys, unseal Vault, and call configure.sh

-   #### File: `vault/policies/kv-secrets.hcl`

    #### Purpose: Policy granting access to secret/\* KV paths

-   #### File: `.sops/usk.json.gpg`

    #### Purpose: GPG-encrypted unseal keys

-   #### File: `.vault-token`
    #### Purpose: Root token stored locally (600 perms) for local dev access

---

---

### 5. 🌍 Environment Variables Required

Set these in your shell before using Vault CLI:

```
export VAULT_ADDR=https://192.168.50.10:4425
export VAULT_CACERT=/etc/ssl/projects/pc-remote/ca/rootCA.crt
export VAULT_TOKEN=$(<~/.vault-token)
```

You can place these in a .envrc (for direnv) or shell init file for convenience.

---

---

### 6. Post-Setup Checklist

```
vault read postgresql/creds/viihna-app
```
