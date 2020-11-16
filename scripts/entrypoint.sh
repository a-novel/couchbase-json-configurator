#!/usr/bin/env bash

set -m

echo "starting couchbase service..."

# Start couchbase default entrypoint with default CMD arguments.
/entrypoint.sh couchbase-server &

echo "couchbase service started in background"

echo "running configuration script..."

# Check if configuration file is present.
[ -f "$DIVAN_SCRIPTS/is_config_here.sh" ] || {
  echo "missing is_config_here.sh script" 1>&2
  exit 1
}
output="$(sh "$DIVAN_SCRIPTS"/is_config_here.sh)" || {
  echo "$output" 1>&2
  exit 1
}

# Check configuration.
[ -f "$DIVAN_SCRIPTS/check_config.sh" ] || {
  echo "missing check_config.sh script" 1>&2
  exit 1
}
output="$(sh "$DIVAN_SCRIPTS"/check_config.sh)" || {
  echo "$output" 1>&2
  exit 1
}

eval "$output"

# Setup cluster.
[ -f "$DIVAN_SCRIPTS/create_cluster.sh" ] || {
  echo "missing create_cluster.sh script" 1>&2
  exit 1
}
output="$(sh "$DIVAN_SCRIPTS"/create_cluster.sh)" || {
  echo "error creating cluster : $output" 1>&2
  exit 1
}

echo "$output"

# Add buckets.
[ -f "$DIVAN_SCRIPTS/create_buckets.sh" ] || {
  echo "missing create_buckets.sh script" 1>&2
  exit 1
}
output="$(sh "$DIVAN_SCRIPTS"/create_buckets.sh)" || {
  echo "error creating buckets : $output" 1>&2
  exit 1
}

echo "$output"

echo "configuration complete"
echo "switching back couchbase service to foreground mode"

# Keep service running in foreground.
fg 1