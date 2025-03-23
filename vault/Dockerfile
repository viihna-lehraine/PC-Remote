# File: vault/Dockerfile

# use the official Vault image
FROM hashicorp/vault:1.14

# install ca-certificates and update them
RUN apk update && apk add --no-cache curl ca-certificates && update-ca-certificates

COPY init/configure.sh /vault/init/configure.sh
RUN chmod +x /vault/init/configure.sh

# copy custom Vault configuration files (optional)
COPY config/config.hcl /vault/config/config.hcl
COPY init/entrypoint.sh /vault/entrypoint.sh

# ensure entrypoint script is executable
RUN chmod +x /vault/entrypoint.sh

# set Vault command
CMD ["/bin/sh", "-c", "/vault/init/entrypoint.sh && vault server -config=/vault/config/config.hcl"]
