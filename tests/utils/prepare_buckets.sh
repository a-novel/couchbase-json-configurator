#!/usr/bin/env bash

echo "$1" > "$DIVAN_CONFIG"

load_data="$(sh "$DIVAN_SCRIPTS/check_config.sh")" || {
  printf "%s" "$load_data" 1>&2
  exit 1
}

eval "$load_data"

sh "$DIVAN_SCRIPTS/create_cluster.sh" 1>/dev/null || exit 1

sh "$DIVAN_SCRIPTS/create_buckets.sh" 1>/dev/null || exit 1

exit 0