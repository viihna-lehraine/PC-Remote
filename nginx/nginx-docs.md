# 🧾 NGINX Proxy Configuration

## Purpose

This NGINX container serves as a **reverse proxy** for the PC Remote application. It protects the bare-metal Fastify server from direct exposure by routing all incoming HTTPS traffic through a secure proxy layer.

It handles:

-   **TLS termination** (HTTPS)
-   **Forwarding HTTP API requests** to the backend
-   **Forwarding WebSocket connections** to a dedicated port
-   Ensuring **real client IP headers** are passed through
-   Keeping the backend _not directly exposed_ to the LAN or WAN

---

## File Structure

```
nginx/
├── conf.d/
│   └── pc-remote.conf       # The active NGINX config file
├── certs/
│   ├── server.crt           # TLS certificate
│   ├── server.key           # TLS private key
│   └── rootCA.crt           # Trusted CA certificate
├── dhparam.pem              # DH parameters for SSL
└── Dockerfile               # NGINX container definition
```

---

## Config Overview (conf.d/pc-remote.conf)

### 🔐 TLS Settings

-   Listens on port `443` with `ssl` and `http2` enabled.
-   Uses **TLS 1.2 and 1.3 only** (secure).
-   Certificate chain:
    -   `server.crt` and `server.key` for the actual cert
    -   `rootCA.crt` for trust chaining
    -   `dhparam.pem` for forward secrecy

### 🌐 `location /`

-   Proxies general HTTP requests to Fastify backend:
    -   `http://192.168.50.10:3050`
-   Headers set:
    -   `X-Real-IP` passes client’s IP
    -   `Host`, `Upgrade`, and `Connection` support upgrades (e.g., for SSE or other long-lived connections)
    -   `proxy_cache_bypass` disables caching for WebSocket-style upgrades

### 🔄 `location /ws/`

-   Routes **WebSocket connections** to a dedicated backend port:
    -   `http://192.168.50.10:3060`
-   Same header pattern but optimized for WebSockets (capital `"Upgrade"` to ensure proper handshake)

---

## 🐳 Dockerfile Explanation

Dockerfile

```
FROM nginx:stable-alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY conf.d/ /etc/nginx/conf.d/
```

-   Base image: Alpine-flavored stable NGINX
-   Removes default.conf to prevent port 80/http exposure
-   Copies custom config to the active NGINX config directory

---

## 🔬 Manual Testing Plan

Pre-requisites
DNS or /etc/hosts entry for pc-remote.local pointing to NGINX container IP
TLS certs in place and trusted locally
Fastify backend running on 192.168.50.10:3050
WebSocket backend on 192.168.50.10:3060
