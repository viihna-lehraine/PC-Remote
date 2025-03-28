# PC Remote

---

## Network

### Main Details

-   LAN IP: 192.168.50.10

### 1. Backend

-   bare metal
    -   :3050 (primary)
    -   :3060 (WebSocket)
    -   :3070 (Vite dev server)

### 2. Nginx

-   Docker Network: pc-remote-net
    -   Docker IP: 172.18.0.4
    -   444:443

### 3. Database

-   Docker Network: pc-remote-net
    -   Docker IP: 172.18.0.3
    -   4590:4590
    -   Note: _Will only accept connections from Vault container over mutual TLS_

### 4. Vault

-   Docker Network: pc-remote-net
    -   Docker IP: 172.18.0.2
        -   4425:4425
