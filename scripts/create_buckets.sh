#!/bin/sh

# Populates the cluster with buckets. When safe mode is enabled, removed buckets in the config will not be deleted on
# the server, and type cannot be changed. Disabling safe mode will delete all buckets removed from configuration, and
# changing a bucket type will also reset the bucket. This feature is aimed for development only and should not be
# disabled in production. It is enabled by default.

eval "$(sh "$DIVAN_SCRIPTS/utils/safe_mode.sh")"

# Get current buckets, if any.
current_buckets="$(curl -s -u "$DIVAN_USERNAME":"$DIVAN_PASSWORD" http://127.0.0.1:8091/pools/default/buckets)"
[ -n "$current_buckets" ] || {
  printf "unable to connect to couchbase, with username %s and password %s\n" "$DIVAN_USERNAME" "$DIVAN_PASSWORD" 1>&2
  exit 1
}
current_buckets_count="$(echo "$current_buckets" | jq -rc '. | length')"
current_buckets_count=${current_buckets_count:=0}
current_buckets="$(echo "$current_buckets" | jq -rc '.[]')"

# Read configured buckets.
bucket_count=$(jq -re '.database.resources.buckets // empty | length' <"${DIVAN_CONFIG}")
bucket_count=${bucket_count:=0}

# Instead of executing all commands in order, we concatenate them within a huge single go string. Thus, if any error
# occurs during the preparation process, no bucket will be updated at all and user will be able to check its config,
# while not interfering w ith production content.
update_cmd=""

sh "$DIVAN_SCRIPTS/create_buckets_utils/check_missing_buckets.sh" "$current_buckets" || exit 1

if [ "$bucket_count" -gt 0 ]; then
  for bucket_name in $(jq -re '.database.resources.buckets | keys | join(" ")' <"${DIVAN_CONFIG}"); do
    update_bucket_cmd="$(
      sh "$DIVAN_SCRIPTS/create_buckets_utils/setup_bucket.sh" "$bucket_name" "$current_buckets_count" "${current_buckets}"
    )" || {
      printf "%s" "$update_bucket_cmd" 1>&2
      exit 1
    }

    [ -n "$update_bucket_cmd" ] && {
      if [ -z "$update_cmd" ]; then
        update_cmd="$update_bucket_cmd"
      else
        update_cmd="$update_cmd && $update_bucket_cmd"
      fi
    }
  done || exit 1
fi

output="$(eval "$update_cmd")" || {
  printf "ERROR : while updating buckets : %s (from command %s)\n" "$output" "$update_cmd" 1>&2
  exit 1
}
