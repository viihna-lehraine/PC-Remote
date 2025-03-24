# 🔐 Vault Initialization & Setup Documentation (PC Remote)

---

## 📦 Vault Docker Container Overview

Vault runs inside a dedicated Docker container with:

-   Custom TLS configuration

-   Pre-mounted certificates

-   Configured policies

-   Postgres dynamic secrets integration

All Vault setup is manual post-docker compose up (for now).

---

---

## Setup Flow Summary

### 1. Bring Up the Stack

-   `docker compose up -d`

-   This starts Vault in a sealed state, with no initialized secrets engine or policies applied yet.

-   Vault’s services are running but unconfigured and unsealed at this point.

### 2. Unseal Vault

-   After bringing up the stack, manually unseal Vault by running:

-   `sudo ./scripts/init_vault.sh`

This script performs the following tasks

-   #### 1. 🔐 Decrypts /home/viihna/Projects/pc-remote/.sops/usk.json.gpg (if needed)

-   #### 2. 🔑 Applies all unseal keys (from decrypted usk.json)

-   #### 3. Shreds the plaintext file after unsealing

-   #### 4. Runs /vault/init/configure.sh inside the Vault container to configure the Vault instance.

**_Note: Vault must be fully unsealed before any secrets engines or policies can be written._**

---

---

### 3. Vault Entry Configuration (/vault/init/configure.sh)

Once Vault is unsealed, this script runs inside the Vault container:

-   Applies the kv-secrets policy (loaded from /vault/policies/kv-secrets.hcl)

-   Enables the PostgreSQL secrets engine (if it isn't already enabled)

-   Configures PostgreSQL plugin for dynamic secrets

-   Writes the viihna-app role for dynamic DB credential issuance

**_Important: This step is essential for enabling the Postgres dynamic secrets feature and setting up Vault to issue credentials dynamically._**

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

Once Vault is initialized, use this command to test that your dynamic credentials are working properly:

```
vault read postgresql/creds/viihna-app
```

This will retrieve dynamically generated credentials for PostgreSQL using the `viihna-app` role.

---

### 7. Detailed Script Breakdown

`scripts/up.sh`

This is the main entrypoint that orchestrates the Vault container setup, ensuring that Vault is unsealed, configured, and securely initialized:

-   Decrypts the Vault root token and shreds it

-   Starts Vault if not already running

-   Waits for Vault to unseal and applies the configuration

-   Rotates and encrypts the root token with SOPS

-   Shreds plaintext tokens to ensure they don’t linger

`scripts/init_vault.sh`

This script handles the unsealing process, making sure that:

-   The unseal key file is decrypted if necessary

-   Each unseal key is applied to unlock Vault

-   The unseal key file is shredded after use to maintain security

`scripts/wait-for-vault.sh`

This script ensures that Vault is initialized and unsealed before proceeding. It:

-   Polls the /sys/health endpoint to verify Vault is initialized and unsealed

-   Continues waiting until Vault is ready to accept requests

`scripts/fetch-approle-credentials.sh`

Fetches the AppRole credentials for the Vault viihna-app role, allowing you to interact with Vault using the dynamic credentials.

`scripts/encrypt-approle.sh`

Encrypts the fetched AppRole credentials using SOPS, ensuring sensitive data is encrypted and protected. This is important for securing your credentials and storing them in a safe location.

`scripts/encrypt-root-token.sh`

Encrypts the Vault root token using SOPS for secure storage. After encryption, the plaintext root token is shredded to prevent accidental exposure.

---

### 8. Vault Token Rotation & Security

At the end of the setup process, the Vault root token is rotated and encrypted with SOPS:

1. The root token is created with limited TTL.

2. The token is revoked, and the previous root token is securely shredded.

3. A new encrypted root token is created and stored securely using SOPS, ensuring that the plaintext token is never left exposed.

---

### 9. Next Steps:

Once Vault is fully initialized and configured, you should use AppRoles for your applications instead of relying on the root token. This will ensure that the system operates with least-privilege access.
