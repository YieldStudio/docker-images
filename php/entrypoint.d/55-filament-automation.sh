#!/bin/sh
script_name="filament-automations"

# Set default values for Laravel automations
: "${AUTORUN_ENABLED:=false}"

if [ "$DISABLE_DEFAULT_CONFIG" = "false" ]; then
    # Check to see if an Artisan file exists and assume it means Laravel is configured.
    if [ -f "$APP_BASE_DIR/artisan" ] && [ "$AUTORUN_ENABLED" = "true" ]; then
        echo "Checking for Filament automations..."
        ############################################################################
        # artisan icons:cache
        ############################################################################
        if [ "${AUTORUN_LARAVEL_ICONS:=true}" = "true" ]; then
            set +e
            echo "🚀 Caching Blade Icons..."
            php "$APP_BASE_DIR/artisan" icons:cache
            if [ $? -eq 0 ]; then
                echo "✅ Blade Icons cached successfully."
            fi
            set -e
        fi

        ############################################################################
        # artisan filament:optimize
        ############################################################################
        if [ "${AUTORUN_LARAVEL_FILAMENT_OPTIMIZE:=true}" = "true" ]; then
            set +e
            echo "🚀 Optimizing Filament..."
            php "$APP_BASE_DIR/artisan" filament:optimize
            if [ $? -eq 0 ]; then
                echo "✅ Filament optimized successfully."
            fi
            set -e
        fi
    fi
else
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal 'false', so automations will NOT be performed."
    fi
fi