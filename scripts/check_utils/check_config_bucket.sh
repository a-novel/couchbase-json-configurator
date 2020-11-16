#!/bin/sh

bucket_name="$1"

# Bucket name cannot be longer than 100 characters.
# https://docs.couchbase.com/server/current/rest-api/rest-bucket-create.html#name
[ "${#bucket_name}" -le 100 ] || {
  printf "bucket name must be no more than 100 characters" 1>&2
  exit 1
}

# Couchbase applies character restrictions on bucket names.
# https://docs.couchbase.com/server/current/rest-api/rest-bucket-create.html#name
if expr "x$bucket_name" : '.*[^0-9a-zA-Z_.%-]' >/dev/null; then
  printf "non valid bucket name '%s' : name can only contain alphanumeric characters, \
'.', '-', '_' and '%%'" "$bucket_name" 1>&2
  exit 1
fi

bucket_ram=$(jq -re ".database.resources.buckets[\"${bucket_name}\"].ramSize // empty" <"${DIVAN_CONFIG}")

# Bucket RAM is required, and should not be lower than 100Mb per bucket.
# https://docs.couchbase.com/server/current/rest-api/rest-bucket-create.html#ramquotamb
if [ -z "$bucket_ram" ] || [ "$bucket_ram" -lt 100 ]; then
  printf "non valid ramSize value '%s' for bucket %s : must be a number greater than or equal to 100\n" \
    "$bucket_ram" "$bucket_name" 1>&2
  exit 1
fi

bucket_type="$(jq -re ".database.resources.buckets[\"${bucket_name}\"].type // empty" <"${DIVAN_CONFIG}")"

# Bucket type can be either ephemeral or couchbase. The memcached type was not allowed here, since it is deprecated.
# https://docs.couchbase.com/server/current/rest-api/rest-bucket-create.html#buckettype
# https://docs.couchbase.com/server/current/learn/buckets-memory-and-storage/buckets.html#bucket-types
if [ -n "$bucket_type" ] && [ "$bucket_type" != "ephemeral" ] && [ "$bucket_type" != "couchbase" ]; then
  printf "non valid type value '%s' for bucket %s : only 'ephemeral' and 'couchbase' are allowed\n" \
    "$bucket_type" "$bucket_name" 1>&2
  exit 1
fi

# Specifies the priority of this bucket’s background tasks.
# https://docs.couchbase.com/server/current/cli/cbcli/couchbase-cli-bucket-create.html
bucket_priority="$(jq -re ".database.resources.buckets[\"${bucket_name}\"].priority // empty" <"${DIVAN_CONFIG}")"
if [ -n "$bucket_priority" ] && [ "$bucket_priority" != "high" ] && [ "$bucket_priority" != "low" ]; then
  printf "non valid priority value '%s' for bucket %s : only 'low' and 'high' are allowed\n" \
    "$bucket_priority" "$bucket_name" 1>&2
  exit 1
fi

# Defines the bucket behavior in case of data overflowing the bucket capacity.
# Eviction policies are different for couchbase and ephemeral buckets, since they both use different ways to
# manipulate data.
# https://docs.couchbase.com/server/current/rest-api/rest-bucket-create.html#evictionpolicy
bucket_eviction_policy="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].evictionPolicy // empty" <"${DIVAN_CONFIG}"
)"

if [ -n "$bucket_eviction_policy" ]; then
  if [ -z "$bucket_type" ] || [ "$bucket_type" = "couchbase" ]; then
    # Note that even if data is ejected from RAM, it will not be lost since couchbase buckets will save it on disk.
    # - Value-only: Only key-values are removed. Generally, this favors performance at the expense of memory.
    # - FullEviction: All data — including keys, key-values, and metadata — is removed. Generally, this favors
    #   memory at the expense of performance.
    [ "$bucket_eviction_policy" = "valueOnly" ] || [ "$bucket_eviction_policy" = "fullEviction" ] || {
      printf "non valid evictionPolicy value '%s' for bucket %s : only 'valueOnly' and 'fullEviction' are \
allowed for couchbase buckets\n" "$bucket_eviction_policy" "$bucket_name" 1>&2
      exit 1
    }
  else
    # For an Ephemeral bucket, ejection removes all of an item’s data: however, a tombstone (a record of the
    # ejected item, which includes keys and metadata) is retained until the next scheduled purge of metadata for
    # the current node. See https://docs.couchbase.com/server/current/learn/buckets-memory-and-storage/storage.html
    # for more information.
    # - noEviction: Resident data-items remain in RAM. No additional data can be added; and attempts to add data
    #   therefore fail.
    # - nruEviction: Resident data-items are ejected from RAM, to make way for new data. For an Ephemeral bucket,
    #   this means that data, which is resident in memory (but, due to this type of bucket, can never be on disk),
    #   is removed from memory. Therefore, if removed data is subsequently needed, it cannot be re-acquired from
    #   Couchbase Server.
    [ "$bucket_eviction_policy" = "noEviction" ] || [ "$bucket_eviction_policy" = "nruEviction" ] || {
      printf "non valid evictionPolicy value '%s' for bucket %s : only 'noEviction' and 'nruEviction' are \
allowed for ephemeral buckets\n" "$bucket_eviction_policy" "$bucket_name" 1>&2
      exit 1
    }
  fi
fi

# Flushing deletes every object that a bucket contains.
# https://docs.couchbase.com/server/current/manage/manage-buckets/flush-bucket.html#:~:text=Once%20enabled%2C%20flushing%20can%20be,flushing%20of%20the%20bucket%20occurs.
bucket_flush="$(jq -re ".database.resources.buckets[\"${bucket_name}\"].flush // empty" <"${DIVAN_CONFIG}")"
if [ -n "$bucket_flush" ] && [ "$bucket_flush" != "true" ] && [ "$bucket_flush" != "false" ]; then
  printf "non valid flush value '%s' for bucket %s : should be a boolean\n" "$bucket_flush" "$bucket_name" \
    1>&2
  exit 1
fi

bucket_purge_interval="$(
  jq -re ".database.resources.buckets[\"$bucket_name\"].purgeInterval // empty" <"${DIVAN_CONFIG}"
)"

low_limit="0.04"
[ "$bucket_type" = "ephemeral" ] && low_limit="0.007"

[ -z "$bucket_purge_interval" ] || {
  [ "$(echo "scale=0;${bucket_purge_interval}/${low_limit}" | bc)" -ge 1 ] &&
    [ "$(echo "scale=0;${bucket_purge_interval}/60.001" | bc)" -lt 1 ]
} || {
  printf "non valid purgeInterval value '%s' for bucket %s : should be a number between %s and 60" \
    "$bucket_purge_interval" "$bucket_name" "$low_limit" 1>&2
  exit 1
}

output="$(sh "$DIVAN_SCRIPTS/utils/check_compaction_settings.sh" ".database.resources.buckets[\"$bucket_name\"]" 2>&1)" || {
  printf "error in compaction settings for bucket %s : %s\n" "$bucket_name" "$output" 1>&2
  exit 1
}

[ -z "$output" ] || [ "$bucket_type" != "ephemeral" ] || {
  printf "compaction is only available for couchbase buckets, for bucket %s" \
  "$bucket_name" 1>&2
  exit 1
}

echo "$bucket_ram"
exit 0
