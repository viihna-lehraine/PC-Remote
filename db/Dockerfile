# File: db/Dockerfile

# use the official Postgres image
FROM postgres:17.0

# install ca-certificates and update them
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates

# copy custom PostgreSQL configuration files (optional)
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf

# set the default command (inherits from postgres image)
CMD ["postgres"]
