# Vault Development Plan

---

### 1. Gate behind its own reverse proxy

### 2. Edge IP Filtering and Rate Limiting

    - Use Nginx (or other reverse proxy) to apply coarse access controls before Vault sees the request
    - Block by IP or CIDR
    - Apply rate limits to slow brute-force attempts
    - Instantly deny unknown ```User-Agent``` headers or malformed requests

### 3. TLS Termination + Certificate Validation

    - Though Vault uses mTLS internally, offload that to the reverse proxy and enforce strict cert validation
    - Only allow client certs signed by your internal CA
    - Reject expired or invalid certs before Vault even sees them

### 3. Hidden Paths & Decoys

    - If someone does port scan or stumble onto Vault, it could be:
    	- Gated behind a different path (/api/.vault/ or /v1/system/core/safe)
    	- Only resolvable via internal DNS (e.g., vault.internal.viihna.lan)
    	- Disguised behind a basic auth wall or dummy static page
    - Audit & Intrusion Detection
    	- Log access attempts at the proxy layer separately from Vault's audit logs. Weird requests or high error rates can trigger...
    	- Alerts to Discord/Slack
    	- Auto-lockdowns (e.g., fail2ban IP bans)
    	- Core dumps (for forensics)
    - Zero Trust Design
    	- Vault itself should live in a zero trust mindset
    	- Reverse proxy = identity-aware gateway
    	- Vault only accepts connections from that proxy
    	- All other inbound traffic is dropped or blackholed

---

II. ## Proposed Structure

```
[Internet/WAN]
     ↓
[NGINX Reverse Proxy]
  - TLS Termination
  - mTLS optional
  - Path rewrites / hiding
  - Rate limits & ACLs
     ↓
[Vault Server]
  - Listens only on localhost or private subnet
```
