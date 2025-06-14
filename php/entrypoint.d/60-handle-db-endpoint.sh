#!/bin/sh
script_name="db-endpoint-automations"

# Set default values for Laravel automations
: "${AUTORUN_ENABLED:=false}"

if [ "$DISABLE_DEFAULT_CONFIG" = "false" ]; then
    # Check if DB_ENDPOINT is set
    if [ -n "$DB_ENDPOINT" ]; then
        export DB_CONNECTION="pgsql"
        export DB_HOST="$(echo "$DB_ENDPOINT" | sed -E 's|^postgres://([^:]+):.*|\1|')"
        export DB_PORT="$(echo "$DB_ENDPOINT" | sed -E 's|^postgres://[^:]+:([^/]+).*|\1|')"
        export DB_DATABASE="$(echo "$DB_ENDPOINT" | sed -E 's|^postgres://[^/]+/([^?]+).*|\1|')"
    else
        echo "No DB endpoint set or autorun is disabled."
    fi
else
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal 'false', so automations will NOT be performed."
    fi
fi