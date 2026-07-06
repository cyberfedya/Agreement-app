# Postgres

Uses the stock `postgres:16-alpine` image (see `docker-compose.yml`). Init scripts, if
needed, go in this folder and are mounted into `/docker-entrypoint-initdb.d`.
