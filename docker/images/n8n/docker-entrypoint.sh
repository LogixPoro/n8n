#!/bin/sh

set -e

# Add optional telemetry
export N8N_VERSION=${N8N_VERSION:-unknown}
export N8N_COMMIT_SHA=${N8N_COMMIT_SHA:-unknown}

exec "$@"
