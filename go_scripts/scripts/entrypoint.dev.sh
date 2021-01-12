#!/usr/bin/env bash

set -m

# Start couchbase default entrypoint with default CMD arguments.
/entrypoint.sh couchbase-server &

cd "$DIVAN_SCRIPTS" && go get -u -v ./...

# Keep service running in foreground.
fg 1