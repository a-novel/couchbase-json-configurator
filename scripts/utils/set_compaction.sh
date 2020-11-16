#!/bin/sh

url="$1"

bucket_fragmentation_threshold_percentage="$2"
bucket_fragmentation_threshold_size="$3"
bucket_view_fragmentation_threshold_percentage="$4"
bucket_view_fragmentation_threshold_size="$5"
bucket_fragmentation_from_hour="$6"
bucket_fragmentation_from_minute="$7"
bucket_fragmentation_to_hour="$8"
bucket_fragmentation_to_minute="$9"
bucket_abort_outside="${10}"
bucket_purge_interval="${11}"
bucket_parallel_compaction="${12}"
force_set="${13}"

auto_compaction=0
{
  [ -n "$bucket_fragmentation_threshold_percentage" ] || \
  [ -n "$bucket_fragmentation_threshold_size" ] || \
  [ -n "$bucket_view_fragmentation_threshold_percentage" ] || \
  [ -n "$bucket_view_fragmentation_threshold_size" ] || \
  [ -n "$bucket_fragmentation_from_hour" ] || \
  [ -n "$bucket_fragmentation_from_minute" ] || \
  [ -n "$bucket_fragmentation_to_hour" ] || \
  [ -n "$bucket_fragmentation_to_minute" ] || \
  [ -n "$bucket_abort_outside" ] || \
  [ -n "$bucket_purge_interval" ]
} && auto_compaction=1

curl_instruction=""

[ -n "$force_set" ] && [ "$auto_compaction" -eq 0 ] && {
  echo "curl -sX POST -u '$DIVAN_USERNAME':'$DIVAN_PASSWORD' \
'$url' -d parallelDBAndViewCompaction=false"
  exit 0
}

[ "$auto_compaction" -eq 0 ] && {
  echo "curl -sX POST -u '$DIVAN_USERNAME':'$DIVAN_PASSWORD' \
'$url' -d autoCompactionDefined=false"
  exit 0
}

[ -n "$bucket_parallel_compaction" ] || bucket_parallel_compaction="false"

curl_instruction="curl -sX POST -u '$DIVAN_USERNAME':'$DIVAN_PASSWORD' \
'$url' -d autoCompactionDefined=true \
-d \"parallelDBAndViewCompaction=$bucket_parallel_compaction\""

[ -z "$bucket_fragmentation_threshold_percentage" ] || \
curl_instruction="$curl_instruction -d \"databaseFragmentationThreshold[percentage]=$bucket_fragmentation_threshold_percentage\""

[ -z "$bucket_fragmentation_threshold_size" ] || \
curl_instruction="$curl_instruction -d \"databaseFragmentationThreshold[size]=$((
bucket_fragmentation_threshold_size * 1048576
))\""

 [ -z "$bucket_view_fragmentation_threshold_percentage" ] || \
curl_instruction="$curl_instruction -d \"viewFragmentationThreshold[percentage]=$bucket_view_fragmentation_threshold_percentage\""

[ -z "$bucket_view_fragmentation_threshold_size" ] || \
curl_instruction="$curl_instruction -d \"viewFragmentationThreshold[size]=$((
bucket_view_fragmentation_threshold_size * 1048576
))\""

[ -z "$bucket_fragmentation_from_hour" ] || \
curl_instruction="$curl_instruction -d \"allowedTimePeriod[fromHour]=$bucket_fragmentation_from_hour\""
[ -z "$bucket_fragmentation_from_minute" ] || \
curl_instruction="$curl_instruction -d \"allowedTimePeriod[fromMinute]=$bucket_fragmentation_from_minute\""

[ -z "$bucket_fragmentation_to_hour" ] || \
curl_instruction="$curl_instruction -d \"allowedTimePeriod[toHour]=$bucket_fragmentation_to_hour\""
[ -z "$bucket_fragmentation_to_minute" ] || \
curl_instruction="$curl_instruction -d \"allowedTimePeriod[toMinute]=$bucket_fragmentation_to_minute\""

[ -z "$bucket_abort_outside" ] || \
curl_instruction="$curl_instruction -d \"allowedTimePeriod[abortOutside]=$bucket_abort_outside\""

[ -z "$bucket_purge_interval" ] && bucket_purge_interval=3
curl_instruction="$curl_instruction -d \"purgeInterval=$bucket_purge_interval\""

echo "$curl_instruction"
exit 0