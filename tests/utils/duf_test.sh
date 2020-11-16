#!/usr/bin/env bash

source="$(cd "$(dirname "$0")" && pwd)"
config_with_defaults_buckets="$1"
config_with_value_buckets="$2"
expect_defaults="$3"
expect_values="$4"

config_with_defaults="{
  \"database\": {
    \"username\": \"Administrator\",
    \"password\": \"password\",
    \"resources\": {
      \"ramSize\": 1024,
      \"ftsRamSize\": 256,
      \"indexRamSize\": 256,
      \"buckets\": $config_with_defaults_buckets
    }
  }
}"

config_with_value="{
  \"database\": {
    \"username\": \"Administrator\",
    \"password\": \"password\",
    \"resources\": {
      \"ramSize\": 1024,
      \"ftsRamSize\": 256,
      \"indexRamSize\": 256,
      \"buckets\": $config_with_value_buckets
    }
  }
}"

defaults="$(echo "$expect_defaults" | jq -rc '.[]')"
values="$(echo "$expect_values" | jq -rc '.[]')"

output="$(sh "$source/prepare_buckets.sh" "$config_with_defaults" 2>&1)" || {
  printf "unable to create buckets : %q" "$output" 1>&2
  exit 1
}

output="$(sh "$source/wait_for_match.sh" $defaults 2>&1)" || {
  printf "bucket returned wrong defaults : %s" "$output" 1>&2
  exit 1
}

output="$(sh "$source/prepare_buckets.sh" "$config_with_value" 2>&1)" || {
  printf "unable to update buckets : %q" "$output" 1>&2
  exit 1
}

output="$(sh "$source/wait_for_match.sh" $values 2>&1)" || {
  printf "bucket returned wrong values : %s" "$output" 1>&2
  exit 1
}

output="$(sh "$source/prepare_buckets.sh" "$config_with_defaults" 2>&1)" || {
  printf "unable to update buckets on fallback : %q" "$output" 1>&2
  exit 1
}

output="$(sh "$source/wait_for_match.sh" $defaults 2>&1)" || {
  printf "bucket returned wrong defaults on fallback : %s" "$output" 1>&2
  exit 1
}

exit 0