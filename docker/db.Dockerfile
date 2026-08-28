FROM golang:1.26 AS gosu-fetch
RUN CGO_ENABLED=0 go install github.com/tianon/gosu@latest

FROM mysql:8.0.33

RUN microdnf remove -y mysql-shell && microdnf clean all

ENV MYSQL_DATABASE=accounts

COPY --from=gosu-fetch /go/bin/gosu /usr/local/bin/gosu

COPY db_backup.sql /docker-entrypoint-initdb.d/db_backup.sql