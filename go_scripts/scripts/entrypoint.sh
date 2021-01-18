#!/usr/bin/env bash

set -m

cd "$DIVAN_SCRIPTS" || exit
go get -u -v ./...

echo "starting couchbase service..."

# Start couchbase default entrypoint with default CMD arguments.
nohup /entrypoint.sh couchbase-server &

echo "couchbase service started in background"
echo "running configuration script..."

nohup go run main.go &

echo "configuration complete"
echo "switching back couchbase service to foreground mode"

# Keep service running in foreground.
fg %1