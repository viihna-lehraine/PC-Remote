# File: db/Dockerfile

# use the official Postgres image
FROM postgres:17.0

# change Postgres UID and GID to avoid conflicts with host
RUN groupmod -g 1010 postgres && \
	usermod -u 1010 -g 1010 postgres

# install ca-certificates and update them
RUN apt-get update && apt-get install -y gosu ca-certificates && update-ca-certificates

# copy custom PostgreSQL configuration files
COPY conf.d/postgresql.conf /etc/postgresql/postgresql.conf
COPY conf.d/pg_hba.conf /etc/postgresql/pg_hba.conf

# copy custom entrypoint script
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["postgres"]
