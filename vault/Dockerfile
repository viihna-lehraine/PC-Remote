# File: vault/Dockerfile

# use the official Vault image
FROM hashicorp/vault:1.14

# install ca-certificates and update them
RUN apk update && apk add ca-certificates && update-ca-certificates

# copy custom Vault configuration files (optional)
COPY config/config.hcl /vault/config/config.hcl
COPY init/entrypoint.sh /vault/entrypoint.sh

# ensure entrypoint script is executable
RUN chmod +x /vault/entrypoint.sh

# set Vault command
CMD ["/bin/sh", "-c", "/vault/init/entrypoint.sh && vault server -config=/vault/config/config.hcl"]
