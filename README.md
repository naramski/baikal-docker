# Baikal Docker image

This image runs [Baikal](https://sabre.io/baikal/), a CalDAV and CardDAV server,
with Apache and PHP. It builds Baikal 0.13.0 on `php:8.4-apache`.

On its first start, the container creates
`/var/www/baikal/config/baikal.yaml` from the `BAIKAL_*` environment variables
listed below. Once that file exists, it is left unchanged; changing environment
variables does not reconfigure an existing installation. Edit or remove the
configuration file (and restart the container) to apply new initial settings.

## Run

Build the image:

```sh
docker build -t baikal .
```

Run it with persistent Baikal data:

```sh
docker run -d \
  --name baikal \
  --publish 8080:80 \
  --volume baikal-data:/var/www/baikal \
  --env BAIKAL_SYSTEM_ADMIN_PASSWORD='change-this-password' \
  baikal
```

Then open `http://localhost:8080/` for the DAV endpoint. The Baikal
administration interface is available at `http://localhost:8080/admin/`.

The `/var/www/baikal` volume persists the configuration, SQLite database, and
other Baikal data. It is recommended for both SQLite and external database
setups because it keeps the generated configuration across container
replacements.

If `BAIKAL_SYSTEM_ADMIN_PASSWORD` is omitted during the first initialization,
the entrypoint generates a random password and writes it to the container log:

```sh
docker logs baikal
```

Set this variable explicitly in production rather than relying on the logged
password.

## Configuration

All variables below are used only while
`/var/www/baikal/config/baikal.yaml` does not yet exist. Unless otherwise
noted, values are written as strings, including empty strings. Single quotes in
values are escaped correctly for YAML.

### System options

| Variable | Default | Description |
| --- | --- | --- |
| `BAIKAL_SYSTEM_CONFIGURED_VERSION` | `0.13.0` | Baikal configuration version written to `configured_version`. Normally leave this unchanged. |
| `BAIKAL_SYSTEM_TIMEZONE` | `Europe/Brussels` | Time zone written to `timezone`, for example `UTC` or `America/New_York`. |
| `BAIKAL_SYSTEM_CARD_ENABLED` | `true` | Enables CardDAV. Must be exactly `true` or `false`. |
| `BAIKAL_SYSTEM_CAL_ENABLED` | `true` | Enables CalDAV. Must be exactly `true` or `false`. |
| `BAIKAL_SYSTEM_DAV_AUTH_TYPE` | `Digest` | DAV authentication type written to `dav_auth_type`. |
| `BAIKAL_SYSTEM_ADMIN_PASSWORD` | Random value generated at first start | Password for the Baikal `admin` account. Its SHA-256 hash is stored in the configuration; when unset, the generated password is printed to standard error. |
| `BAIKAL_SYSTEM_FAILED_ACCESS_MESSAGE` | `user %u authentication failure for Baikal` | Failed-authentication message written to `failed_access_message`. |
| `BAIKAL_SYSTEM_AUTH_REALM` | `BaikalDAV` | HTTP authentication realm. This value is also included when hashing `BAIKAL_SYSTEM_ADMIN_PASSWORD`; set it before the first start. |
| `BAIKAL_SYSTEM_BASE_URI` | Empty | Base URI written to `base_uri`. |
| `BAIKAL_SYSTEM_INVITE_FROM` | `noreply@localhost` | Sender address written to `invite_from`. |

### Database options

| Variable | Default | Description |
| --- | --- | --- |
| `BAIKAL_DATABASE_BACKEND` | `sqlite` | Database backend written to `backend`. Leave as `sqlite` for the built-in SQLite initialization; use the backend value required by an external Baikal database configuration. |
| `BAIKAL_DATABASE_SQLITE_FILE` | `/var/www/baikal/Specific/db/db.sqlite` | Path to the SQLite database written to `sqlite_file`. When the backend is unset or `sqlite`, the image creates the default SQLite database if it does not exist. |
| `BAIKAL_DATABASE_MYSQL_HOST` | Empty | MySQL host written to `mysql_host`. |
| `BAIKAL_DATABASE_MYSQL_DBNAME` | Empty | MySQL database name written to `mysql_dbname`. |
| `BAIKAL_DATABASE_MYSQL_USERNAME` | Empty | MySQL user written to `mysql_username`. |
| `BAIKAL_DATABASE_MYSQL_PASSWORD` | Empty | MySQL password written to `mysql_password`. Treat as a secret. |
| `BAIKAL_DATABASE_MYSQL_CA_CERT` | Empty | MySQL CA certificate value or path written to `mysql_ca_cert`. |
| `BAIKAL_DATABASE_ENCRYPTION_KEY` | `f2911d86e567387f2c9717206101200a` | Database encryption key written to `encryption_key`. Set a unique secret before the first start. |
| `BAIKAL_DATABASE_PGSQL_HOST` | Empty | PostgreSQL host written to `pgsql_host`. |
| `BAIKAL_DATABASE_PGSQL_DBNAME` | Empty | PostgreSQL database name written to `pgsql_dbname`. |
| `BAIKAL_DATABASE_PGSQL_USERNAME` | Empty | PostgreSQL user written to `pgsql_username`. |
| `BAIKAL_DATABASE_PGSQL_PASSWORD` | Empty | PostgreSQL password written to `pgsql_password`. Treat as a secret. |

### SQLite example

SQLite is the default and needs no database environment variables:

```sh
docker run -d \
  --name baikal \
  --publish 8080:80 \
  --volume baikal-data:/var/www/baikal \
  --env BAIKAL_SYSTEM_TIMEZONE=UTC \
  --env BAIKAL_SYSTEM_ADMIN_PASSWORD='change-this-password' \
  baikal
```

### External database example

Provide the applicable database settings on the initial start. This example
shows the variables the image writes for a MySQL-based Baikal configuration:

```sh
docker run -d \
  --name baikal \
  --publish 8080:80 \
  --volume baikal-data:/var/www/baikal \
  --env BAIKAL_SYSTEM_ADMIN_PASSWORD='change-this-password' \
  --env BAIKAL_DATABASE_BACKEND=mysql \
  --env BAIKAL_DATABASE_MYSQL_HOST=mysql \
  --env BAIKAL_DATABASE_MYSQL_DBNAME=baikal \
  --env BAIKAL_DATABASE_MYSQL_USERNAME=baikal \
  --env BAIKAL_DATABASE_MYSQL_PASSWORD='change-this-password' \
  baikal
```

The image only writes the selected values to Baikal’s configuration. Ensure the
chosen Baikal backend, database server, credentials, and required PHP database
support are available for the deployment.

## Ports and commands

Apache listens on container port `80`. Publish it with `--publish`, as shown
above. The image entrypoint performs first-run configuration and then executes
the supplied command; by default it runs `apache2-foreground`.