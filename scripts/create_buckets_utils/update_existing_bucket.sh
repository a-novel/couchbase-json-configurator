#!/bin/sh

bucket_name="$1"
bucket_type="$2"
bucket_ram="$3"
bucket_priority="$4"
bucket_eviction_policy="$5"
flush="$6"
bucket_compaction_threshold_percentage="$7"
bucket_compaction_threshold_size="$8"
bucket_view_compaction_threshold_percentage="$9"
bucket_view_compaction_threshold_size="${10}"
bucket_compaction_from_hour="${11}"
bucket_compaction_from_minute="${12}"
bucket_compaction_to_hour="${13}"
bucket_compaction_to_minute="${14}"
bucket_abort_outside="${15}"
bucket_purge_interval="${16}"
bucket_parallel_compaction="${17}"
old_bucket="${18}"

update_string=""
curl_string=""

# Coucbase rest api returns ram size in bytes, so we need to convert our Mb value for comparison.
bucket_ram_bytes=$((bucket_ram * 1048576))

# Update RAM.
[ "$bucket_ram_bytes" = "$(echo "$old_bucket" | jq -re ".quota.ram")" ] || \
update_string="$update_string --bucket-ramsize $bucket_ram"

# Ephemeral buckets eviction policy cannot be updated.
old_bucket_eviction_policy="$(echo "$old_bucket" | jq -re ".evictionPolicy")"

is_different_policy=0
{
  [ -z "$bucket_eviction_policy" ] && {
    [ "$old_bucket_eviction_policy" = "valueOnly" ] || \
    [ "$old_bucket_eviction_policy" = "noEviction" ]
  }
} || [ "$bucket_eviction_policy" = "$old_bucket_eviction_policy" ] || is_different_policy=1

[ "$is_different_policy" -eq 1 ] && {
  [ -n "$bucket_eviction_policy" ] || bucket_eviction_policy="valueOnly"
  update_string="$update_string --bucket-eviction-policy $bucket_eviction_policy"
}

# The bucket priority actually sets a thread number associated with the bucket. 8 threads mins high priority,
# while 3 means low. Every other value is ignored and considered as low (bucket default priority).
old_bucket_threads="$(echo "$old_bucket" | jq -re ".threadsNumber")"

# Check if threadNumber match our priority value, otherwise we have to update it.
{
  {
    [ -z "$bucket_priority" ] || [ "$bucket_priority" = "low" ]
  } && [ "$old_bucket_threads" -lt 8 ]
} || {
  [ "$bucket_priority" = "high" ] && [ "$old_bucket_threads" -eq 8 ]
} || {
  [ -n "$bucket_priority" ] || bucket_priority="low"
  update_string="$update_string --bucket-priority $bucket_priority"
}

# Prevent decreasing RAM volume if the new size cannot handle current data.

current_usage="$(echo "$old_bucket" | jq -re ".basicStats.memUsed")"
[ "$bucket_ram_bytes" -gt "$current_usage" ] || {
  printf "error when updating ram quota of bucket %s : current data uses %s bytes of ram, which is greater \
than the new allocated value '%s' bytes %s\n" "$bucket_name" "$current_usage" "$bucket_ram_bytes" "$(echo "$old_bucket" | jq -re ".basicStats.memUsed")" 1>&2
  exit 1
}

# There is no flush value directly returned within the rest api response. Instead, only when flush is enabled,
# a key is added to the .controller key, named flush with a url value. If this key is present, flush is
# currently enabled.
old_bucket_flush="$(echo "$old_bucket" | jq -re ".controllers.flush // empty")"
{
  {
    [ -z "$flush" ] || [ "$flush" = "false" ]
  } && [ -z "$old_bucket_flush" ]
} || {
  [ -n "$old_bucket_flush" ] && [ "$flush" = "true" ]
} || update_string="$update_string --enable-flush $({ [ "$flush" = "true" ] && echo "1"; } || echo "0")"

if [ -z "$bucket_type" ] || [ "$bucket_type" = "couchbase" ]; then
  curl_string="$(
    sh "$DIVAN_SCRIPTS/utils/set_compaction.sh" "http://127.0.0.1:8091/pools/default/buckets/$bucket_name" \
"$bucket_compaction_threshold_percentage" "$bucket_compaction_threshold_size" \
"$bucket_view_compaction_threshold_percentage" "$bucket_view_compaction_threshold_size" \
"$bucket_compaction_from_hour" "$bucket_compaction_from_minute" \
"$bucket_compaction_to_hour" "$bucket_compaction_to_minute" \
"$bucket_abort_outside" "$bucket_purge_interval" "$bucket_parallel_compaction"
  )" || {
    printf "%s" "$curl_string" 1>&2
    exit 1
  }
else
  # When creating with CLI, ephemeral buckets purgeInterval is defaulted to 1 day.
  # We fix it for better consistency.
  [ -n "$bucket_purge_interval" ] || bucket_purge_interval=3
  curl_string="curl -sX POST -u '$DIVAN_USERNAME':'$DIVAN_PASSWORD' 'http://127.0.0.1:8091/pools/default/buckets/$bucket_name' -d purgeInterval=$bucket_purge_interval"
fi

output=""

if [ "${#update_string}" -gt 0 ]; then
  output="/opt/couchbase/bin/couchbase-cli bucket-edit -c 127.0.0.1 \
--username \"$DIVAN_USERNAME\" --password \"$DIVAN_PASSWORD\" \
--bucket \"$bucket_name\" \
$update_string"
fi

if  [ "${#curl_string}" -gt 0 ]; then
  if [ -z "$output" ]; then
    output="$curl_string"
  else
    output="$output && $curl_string"
  fi
fi

echo "$output"
exit 0