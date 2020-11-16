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

create_string=""

[ -z "$bucket_priority" ] || create_string="${create_string} --bucket-priority $bucket_priority"

[ -z "$bucket_eviction_policy" ] || create_string="${create_string} --bucket-eviction-policy $bucket_eviction_policy"

[ -z "$flush" ] || [ "$flush" = "false" ] || {
  create_string="${create_string} --enable-flush 1"
}

curl_string=""

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

[ -n "$curl_string" ] && curl_string="&& $curl_string"

echo "/opt/couchbase/bin/couchbase-cli bucket-create -c 127.0.0.1 \
--username \"$DIVAN_USERNAME\" --password \"$DIVAN_PASSWORD\" \
--bucket \"$bucket_name\" \
--bucket-type \"$bucket_type\" \
--bucket-ramsize \"$bucket_ram\" \
--bucket-replica 0 \
$create_string --wait $curl_string" && exit 0
