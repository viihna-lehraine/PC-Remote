# File: db/Dockerfile

# use the official Postgres image
FROM postgres:17.0

# install ca-certificates and update them
RUN apt-get update && apt-get install -y gosu ca-certificates && update-ca-certificates

# copy custom PostgreSQL configuration files (optional)
COPY conf.d/postgresql.conf /etc/postgresql/postgresql.conf
COPY conf.d/pg_hba.conf /etc/postgresql/pg_hba.conf

# copy custom entrypoint script
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["postgres"]
