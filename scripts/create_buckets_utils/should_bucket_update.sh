#!/bin/sh

bucket_name="$1"
bucket_type="$2"
bucket_eviction_policy="$3"

current_buckets_count="$4"
current_buckets="$5"

old_bucket_data=""
delete_action=""

# Check if a bucket with the same name already exists (so we need to update it).
if [ "$current_buckets_count" -gt 0 ]; then
  for old_bucket in $current_buckets; do
    # Names match.
    if [ "$bucket_name" = "$(echo "$old_bucket" | jq -re ".name")" ]; then
      old_bucket_data="$old_bucket"

      # In unsafe mode, bucket type can be changed but the bucket then needs to be re-created. This is a development
      # feature only and in production, buckets should be deleted with care.
      old_bucket_type="$(echo "$old_bucket" | jq -re ".bucketType")"
      # Couchbase bucket type is translated to membase once the bucket is created, so we need to convert membase
      # type back for our operations.
      [ "$old_bucket_type" = "membase" ] && old_bucket_type="couchbase"
      # We need to recreate bucket if types do not match in unsafe mode.
      [ "$bucket_type" = "$old_bucket_type" ] || {
        # Cannot be changed in safe mode.
        [ "$SAFE_MODE" -eq 0 ] || {
          printf "ERROR : bucket type cannot be changed, in bucket %s : \
please revert it to %s, or run the image with FORCE_UNSAFE env variable (please note \
it will result in the loss of the entire bucket data).\n" "$bucket_name" "$old_bucket_type" 1>&2
          exit 1
        }

        old_bucket_data=""
      }

      # Ephemeral buckets eviction policy cannot be updated.
      old_bucket_eviction_policy="$(echo "$old_bucket" | jq -re ".evictionPolicy")"

      is_different_policy=0
      {
        [ -z "$bucket_eviction_policy" ] && {
          [ "$old_bucket_eviction_policy" = "valueOnly" ] ||
            [ "$old_bucket_eviction_policy" = "noEviction" ]
        }
      } || [ "$bucket_eviction_policy" = "$old_bucket_eviction_policy" ] || is_different_policy=1

      [ "$is_different_policy" -eq 0 ] || [ "$old_bucket_type" != "ephemeral" ] || [ "$SAFE_MODE" -eq 0 ] || {
        printf "ERROR : eviction policy cannot be changed for ephemeral buckets, in bucket %s : \
please revert it to %s, or run the image with FORCE_UNSAFE env variable (please note \
it will result in the loss of the entire bucket data).\n" "$bucket_name" "$old_bucket_eviction_policy" 1>&2
        exit 1
      }

      [ "$is_different_policy" -eq 1 ] && [ "$bucket_type" = "ephemeral" ] && old_bucket_data=""

      [ -n "$old_bucket_data" ] || {
        delete_action="/opt/couchbase/bin/couchbase-cli bucket-delete -c 127.0.0.1 \
--username \"$DIVAN_USERNAME\" --password \"$DIVAN_PASSWORD\" \
--bucket \"$bucket_name\""
      }

      break
    fi
  done || exit 1
fi

echo "export OLD_BUCKET_DATA='$old_bucket_data' DELETE_ACTION=\"$delete_action\""
exit 0