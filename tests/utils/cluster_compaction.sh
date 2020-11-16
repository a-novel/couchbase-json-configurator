#!/usr/bin/env bash

compaction="$1"
expect="$2"

[ -n "$compaction" ] && compaction=", \"compaction\": $compaction"

echo "{
  \"database\": {
    \"username\": \"Administrator\",
    \"password\": \"password\",
    \"resources\": {
      \"ramSize\": 2048,
      \"ftsRamSize\": 512,
      \"indexRamSize\": 512$compaction
    }
  }
}" > "$DIVAN_CONFIG"

load_data="$(sh "$DIVAN_SCRIPTS/check_config.sh")" || {
  printf "%s" "$load_data" 1>&2
  exit 1
}

eval "$load_data"

output="$(sh "$DIVAN_SCRIPTS/create_cluster.sh" 1>/dev/null)" || {
  printf "# %s\n" "$output" >&3
  exit 1
}

output="$(curl -sX GET -u Administrator:password http://127.0.0.1:8091/settings/autoCompaction)" || {
  printf "# %s\n" "$output" >&3
  exit 1
}

for expected in $(echo "$expect" | jq -rc '[]'); do
  expected_key="$(echo "$expected" | jq -re ".key")"
  expected_value="$(echo "$expected" | jq -re ".value")"
  actual_value="$(echo "$output" | jq -re "$expected_key")"

  [ "$expected_value" = "undefined" ] && expected_value=""
  [ "$actual_value" = "undefined" ] && actual_value=""

  [ "$expected_value" = "$expected_value" ] || {
    printf "wrong value '%s' for %s : expected %s\n" "$actual_value" "$expected_key" "$expected_value" 1>&2
    exit 1
  }
done || exit 1

exit 0