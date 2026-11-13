#!/bin/bash
set -e


# Write an environment variable (or its default) as a single-quoted YAML string,
# escaping embedded single quotes by doubling them.
yaml_string() {
    local env_name=$1 yaml_key=$2 default_value=$3 value char escaped=""
    if [[ -v $env_name ]]; then
        value=${!env_name}
    else
        value=$default_value
    fi

    for ((i = 0; i < ${#value}; i++)); do
        char=${value:i:1}
        if [[ $char == "'" ]]; then
            escaped+="''"
        else
            escaped+="$char"
        fi
    done
    printf "    %s: '%s'\n" "$yaml_key" "$escaped"
}

# Hash the admin password for the configured authentication realm.
# Generate and log a random password when none is defined.
yaml_admin_password() {
    local password password_hash
    if [[ -v BAIKAL_SYSTEM_ADMIN_PASSWORD ]]; then
        password=$BAIKAL_SYSTEM_ADMIN_PASSWORD
    else
        password=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
        printf 'Generated Baikal admin password: %s\n' "$password" >&2
    fi

    password_hash=$(printf '%s' "admin:${BAIKAL_SYSTEM_AUTH_REALM-BaikalDAV}:$password" | sha256sum)
    printf "    admin_passwordhash: '%s'\n" "${password_hash%% *}"
}

# Write an environment variable (or its default) as a YAML boolean, rejecting
# any value other than the literal true or false.
yaml_boolean() {
    local env_name=$1 yaml_key=$2 default_value=$3 value
    if [[ -v $env_name ]]; then
        value=${!env_name}
    else
        value=$default_value
    fi
    case "$value" in
        true|false) printf "    %s: %s\n" "$yaml_key" "$value" ;;
        *) echo "The variable ${env_name} must be true or false" >&2; exit 1 ;;
    esac
}

if [ ! -f /var/www/baikal/config/baikal.yaml ]; then
    echo "First initialization..."

    mkdir -p /var/www/baikal/config

    {
        echo "system:"
        yaml_string BAIKAL_SYSTEM_CONFIGURED_VERSION configured_version 0.13.0
        yaml_string BAIKAL_SYSTEM_TIMEZONE timezone Europe/Brussels
        yaml_boolean BAIKAL_SYSTEM_CARD_ENABLED card_enabled true
        yaml_boolean BAIKAL_SYSTEM_CAL_ENABLED cal_enabled true
        yaml_string BAIKAL_SYSTEM_DAV_AUTH_TYPE dav_auth_type Digest
        yaml_admin_password
        yaml_string BAIKAL_SYSTEM_FAILED_ACCESS_MESSAGE failed_access_message 'user %u authentication failure for Baikal'
        yaml_string BAIKAL_SYSTEM_AUTH_REALM auth_realm BaikalDAV
        yaml_string BAIKAL_SYSTEM_BASE_URI base_uri ''
        yaml_string BAIKAL_SYSTEM_INVITE_FROM invite_from noreply@localhost
        echo "database:"
        yaml_string BAIKAL_DATABASE_SQLITE_FILE sqlite_file /var/www/baikal/Specific/db/db.sqlite
        yaml_string BAIKAL_DATABASE_BACKEND backend sqlite
        yaml_string BAIKAL_DATABASE_MYSQL_HOST mysql_host ''
        yaml_string BAIKAL_DATABASE_MYSQL_DBNAME mysql_dbname ''
        yaml_string BAIKAL_DATABASE_MYSQL_USERNAME mysql_username ''
        yaml_string BAIKAL_DATABASE_MYSQL_PASSWORD mysql_password ''
        yaml_string BAIKAL_DATABASE_MYSQL_CA_CERT mysql_ca_cert ''
        yaml_string BAIKAL_DATABASE_ENCRYPTION_KEY encryption_key f2911d86e567387f2c9717206101200a
        yaml_string BAIKAL_DATABASE_PGSQL_HOST pgsql_host ''
        yaml_string BAIKAL_DATABASE_PGSQL_DBNAME pgsql_dbname ''
        yaml_string BAIKAL_DATABASE_PGSQL_USERNAME pgsql_username ''
        yaml_string BAIKAL_DATABASE_PGSQL_PASSWORD pgsql_password ''
    } > /var/www/baikal/config/baikal.yaml

    if [[ ! -v BAIKAL_DATABASE_BACKEND || "$BAIKAL_DATABASE_BACKEND" == sqlite ]]; then
        if [ ! -f /var/www/baikal/Specific/db/db.sqlite ]; then
            apt install -y sqlite3
            sqlite3 /var/www/baikal/Specific/db/db.sqlite < /var/www/baikal/Core/Resources/Db/SQLite/db.sql
            chown -R www-data:www-data /var/www/baikal
        fi
    fi

fi

exec "$@"