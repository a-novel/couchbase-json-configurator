#!/bin/sh

compaction_threshold_percentage="$(jq -re "$1.compaction.threshold.percentage // empty" <"${DIVAN_CONFIG}")"

compaction_threshold_size="$(jq -re "$1.compaction.threshold.size // empty" <"${DIVAN_CONFIG}")"

view_compaction_threshold_percentage="$(jq -re "$1.compaction.viewThreshold.percentage // empty" <"${DIVAN_CONFIG}")"

view_compaction_threshold_size="$(jq -re "$1.compaction.viewThreshold.size // empty" <"${DIVAN_CONFIG}")"

compaction_from_hour="$(jq -re "$1.compaction.from.hour // empty" <"${DIVAN_CONFIG}")"

compaction_from_minute="$(jq -re "$1.compaction.from.minute // empty" <"${DIVAN_CONFIG}")"

compaction_to_hour="$(jq -re "$1.compaction.to.hour // empty" <"${DIVAN_CONFIG}")"

compaction_to_minute="$(jq -re "$1.compaction.to.minute // empty" <"${DIVAN_CONFIG}")"

abort_outside="$(jq -re "$1.compaction.abortOutside // empty" <"${DIVAN_CONFIG}")"

parallel_compaction="$(jq -re "$1.compaction.parallelCompaction // empty" < "$DIVAN_CONFIG")"

is_compaction_set=0
{
  [ -n "$compaction_threshold_percentage" ] || \
  [ -n "$compaction_threshold_size" ] || \
  [ -n "$view_compaction_threshold_percentage" ] || \
  [ -n "$view_compaction_threshold_size" ] || \
  [ -n "$compaction_from_hour" ] || \
  [ -n "$compaction_from_minute" ] || \
  [ -n "$compaction_to_hour" ] || \
  [ -n "$compaction_to_minute" ] || \
  [ -n "$abort_outside" ] || \
  [ -n "$parallel_compaction" ]
} && is_compaction_set=1

[ "$is_compaction_set" -eq 1 ] || exit 0

is_compaction_interval_set=0
{
  [ -z "$compaction_from_hour" ] &&
  [ -z "$compaction_from_minute" ] &&
  [ -z "$compaction_to_hour" ] &&
  [ -z "$compaction_to_minute" ]
} || is_compaction_interval_set=1

[ "$is_compaction_interval_set" -eq 1 ] && \
[ -z "$compaction_threshold_percentage" ] && \
[ -z "$compaction_threshold_size" ] && \
[ -z "$view_compaction_threshold_percentage" ] && \
[ -z "$view_compaction_threshold_size" ] && {
  printf "cannot set compaction interval if no compaction threshold is set" 1>&2
  exit 1
}

[ -n "$abort_outside" ] && [ "$is_compaction_interval_set" -eq 0 ] && {
  printf "cannot set compaction abortOutside if no compaction timeframe is set" 1>&2
  exit 1
}

[ "$is_compaction_interval_set" -eq 1 ] && [ -z "$compaction_from_hour" ] && {
  printf "missing compaction start hour : compaction interval requires full setup to run" 1>&2
  exit 1
}

[ "$is_compaction_interval_set" -eq 1 ] && [ -z "$compaction_from_minute" ] && {
  printf "missing compaction start minute : compaction interval requires full setup to run" 1>&2
  exit 1
}

[ "$is_compaction_interval_set" -eq 1 ] && [ -z "$compaction_to_hour" ] && {
  printf "missing compaction end hour : compaction interval requires full setup to run" 1>&2
  exit 1
}

[ "$is_compaction_interval_set" -eq 1 ] && [ -z "$compaction_to_minute" ] && {
  printf "missing compaction end minute : compaction interval requires full setup to run" 1>&2
  exit 1
}

[ -z "$compaction_threshold_percentage" ] || {
  [ "$compaction_threshold_percentage" -ge 2 ] && \
  [ "$compaction_threshold_percentage" -le 100 ]
} || {
  printf "non valid compaction threshold percentage value '%s' : should be a number \
between 2 and 100" "$compaction_threshold_percentage" 1>&2
  exit 1
}

[ -z "$compaction_threshold_size" ] || [ "$compaction_threshold_size" -ge 1 ] || {
  printf "non valid compaction threshold size value '%s' : should be a number \
greater than or equal to 1" "$compaction_threshold_size" 1>&2
  exit 1
}

[ -z "$view_compaction_threshold_percentage" ] || {
  [ "$view_compaction_threshold_percentage" -ge 2 ] && \
  [ "$view_compaction_threshold_percentage" -le 100 ]
} || {
  printf "non valid compaction view threshold percentage value '%s' : should be a number \
between 2 and 100" "$view_compaction_threshold_percentage" 1>&2
  exit 1
}

[ -z "$view_compaction_threshold_size" ] || [ "$view_compaction_threshold_size" -ge 1 ] || {
  printf "non valid compaction view threshold size value '%s' : should be a number \
greater than or equal to 1" "$view_compaction_threshold_size" 1>&2
  exit 1
}

[ -z "$compaction_from_hour" ] || {
  [ "$compaction_from_hour" -ge 0 ] &&
  [ "$compaction_from_hour" -lt 24 ]
} || {
  printf "non valid compaction threshold from hour value '%s' : should be a number \
between 0 and 23" "$compaction_from_hour" 1>&2
  exit 1
}

[ -z "$compaction_from_minute" ] || {
  [ "$compaction_from_minute" -ge 0 ] &&
  [ "$compaction_from_minute" -lt 60 ]
} || {
  printf "non valid compaction threshold from minute value '%s' : should be a number \
between 0 and 59" "$compaction_from_minute" 1>&2
  exit 1
}

[ -z "$compaction_to_hour" ] || {
  [ "$compaction_to_hour" -ge 0 ] &&
  [ "$compaction_to_hour" -lt 24 ]
} || {
  printf "non valid compaction threshold to hour value '%s' : should be a number \
between 0 and 23" "$compaction_to_hour" 1>&2
  exit 1
}

[ -z "$compaction_to_minute" ] || {
  [ "$compaction_to_minute" -ge 0 ] &&
  [ "$compaction_to_minute" -lt 60 ]
} || {
  printf "non valid compaction threshold to minute value '%s' : should be a number \
between 0 and 59" "$compaction_to_minute" 1>&2
  exit 1
}

[ -z "$abort_outside" ] || [ "$abort_outside" = "false" ] || [ "$abort_outside" = "true" ] || {
  printf "non valid compaction abortOutside value '%s' : should be a boolean" \
  "$abort_outside" 1>&2
  exit 1
}

[ -z "$parallel_compaction" ] || [ "$parallel_compaction" = "true" ] || \
[ "$parallel_compaction" = "false" ] || {
  printf "non valid compaction parallelCompaction value '%s' : should be a boolean" \
  "$parallel_compaction" 1>&2
  exit 1
}

echo "compaction set"
exit 0