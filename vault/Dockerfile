# File: vault/Dockerfile

# use the official Vault image
FROM hashicorp/vault:1.14

# install ca-certificates and update them
RUN apk update && apk add --no-cache curl ca-certificates jq

RUN update-ca-certificates

# copy custom Vault configuration files (optional)
COPY config/config.hcl /vault/config/config.hcl
COPY policies /vault/policies

COPY init/entrypoint.sh /vault/init/entrypoint.sh
COPY init/configure.sh /vault/init/configure.sh

# ensure init files are executable
RUN chmod +x /vault/init/entrypoint.sh
RUN chmod +x /vault/init/configure.sh

# set Vault command
CMD ["/bin/sh", "-c", "/vault/init/entrypoint.sh && vault server -config=/vault/config/config.hcl"]
