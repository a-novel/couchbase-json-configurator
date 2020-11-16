#!/usr/bin/env bash

elapsed=0
status=1

DIVAN_USERNAME="$(jq -re '.database.username' < "$DIVAN_CONFIG")"
DIVAN_PASSWORD="$(jq -re '.database.password' < "$DIVAN_CONFIG")"

until [ "$elapsed" -eq 30 ] || [ "$status" -eq 0 ]; do
  output="$(
    current_buckets_curl="$(curl -s -u "$DIVAN_USERNAME":"$DIVAN_PASSWORD" http://127.0.0.1:8091/pools/default/buckets)"
    [ -n "$current_buckets_curl" ] || {
      printf "curl request returned empty with username %s and password %s" "$DIVAN_USERNAME" "$DIVAN_PASSWORD"
      exit 1
    }

    current_buckets_count="$(echo "$current_buckets_curl" | jq -rc '. | length')"
    current_buckets_count=${current_buckets_count:=0}
    current_buckets="$(echo "$current_buckets_curl" | jq -rc '.[]')"

    [ "$#" -eq "$current_buckets_count" ] || {
      printf "non valid bucket count : expected %s, got %s\n" "$#" "$current_buckets_count"
      exit 1
    }

    # Do not verify buckets if none are present.
    [ "$#" -gt 0 ] || exit 0

    for bucket in "$@"; do
      current_name="$(echo "$bucket" | jq -re '.name')"
      matching_bucket=""

      for actual_bucket in $current_buckets; do
        name="$(echo "$actual_bucket" | jq -re '.name')"
        [ "$name" = "$current_name" ] && {
          matching_bucket="$actual_bucket"
          break
        }
      done

      [ -n "$matching_bucket" ] || {
        printf "bucket %s not found in cluster\n" "$current_name"
        exit 1
      }

      keys_to_check="$(echo "$bucket" | jq -rc '.check[]')"

      for data in $keys_to_check; do
        key="$(echo "$data" | jq -re '.key')"
        value="$(echo "$data" | jq -re '.value')"
        matching_value="$(echo "$matching_bucket" | jq -re "$key // empty")"

        [ "$matching_value" = "undefined" ] && matching_value=""
        [ "$value" = "undefined" ] && value=""

        [ "$matching_value" = "$value" ] || {
          printf "unexpected value at '%s' : expected %s, got %s (in bucket %s)" "$key" "$value" "$matching_value" "$current_name"
          exit 1
        }
      done || exit 1
    done || exit 1
  )"

  status="$?"
  sleep 1
  elapsed=$((elapsed + 1))
done

[ "$status" -eq 0 ] || echo "$output" 1>&2
exit "$status"