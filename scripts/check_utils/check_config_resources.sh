#!/bin/sh

# Cluster sizing. More information can be found at the page below:
# https://docs.couchbase.com/server/current/install/sizing-general.html

# The Index Service supports the creation of primary and secondary indexes on items stored within Couchbase Server.
# More at https://docs.couchbase.com/server/current/learn/services-and-indexes/services/index-service.html
DIVAN_INDEX_RAM_SIZE="$(jq -re '.database.resources.indexRamSize // empty' <"${DIVAN_CONFIG}")"
# Minimum amount of RAM for index service is 256Mb.
# https://docs.couchbase.com/server/current/install/sizing-general.html#about-couchbase-server-resources
[ "$DIVAN_INDEX_RAM_SIZE" -ge 256 ] || {
  printf "non valid indexRamSize value '%s' : must be greater than or equal to 256\n" \
  "$DIVAN_INDEX_RAM_SIZE" 1>&2
  exit 1
}

# The Search Service supports the creation of specially purposed indexes for Full Text Search.
# More at https://docs.couchbase.com/server/current/learn/services-and-indexes/services/search-service.html
DIVAN_FTS_RAM_SIZE="$(jq -re '.database.resources.ftsRamSize // empty' <"${DIVAN_CONFIG}")"
# Minimum amount of RAM for full-text search service is 256Mb, and recommended equal or above 2048Mb.
# https://docs.couchbase.com/server/current/install/sizing-general.html#about-couchbase-server-resources
[ "$DIVAN_FTS_RAM_SIZE" -ge 256 ] || {
  printf "non valid ftsRamSize value '%s' : must be greater than or equal to 256\n" \
  "$DIVAN_FTS_RAM_SIZE" 1>&2
  exit 1
}

# The Data Service provides access to data.
# More at https://docs.couchbase.com/server/current/learn/services-and-indexes/services/data-service.html
DIVAN_RAM_SIZE="$(jq -re '.database.resources.ramSize // empty' <"${DIVAN_CONFIG}")"
# Since we added an autosize feature, ramSize is set to 0 if not given, then automatically scaled to match buckets
# requirements.
if [ "$DIVAN_RAM_SIZE" = "null" ] || [ -z "$DIVAN_RAM_SIZE" ]; then
  DIVAN_RAM_SIZE=0
fi

# Init the variable calculating the total amount of ram required by the buckets.
bucket_total_ram=0
# Count the total amount of buckets provided by the user. If none are provided, no bucket will be set and user will
# have to add them manually through UI.
bucket_count=$(jq -re '.database.resources.buckets // empty | length' <"${DIVAN_CONFIG}")
bucket_count=${bucket_count:=0}

# Only check bucket configuration if some buckets were provided.
# General information about the cli can be found at https://docs.couchbase.com/server/current/cli/cbcli/couchbase-cli-bucket-create.html
if [ "$bucket_count" -gt 0 ]; then
  for bucket_name in $(jq -re '.database.resources.buckets | keys | join(" ")' <"${DIVAN_CONFIG}"); do
    ram="$(sh "$DIVAN_SCRIPTS/check_utils/check_config_bucket.sh" "$bucket_name")" || {
      printf "%s" "$ram" 1>&2
      exit 1
    }

    bucket_total_ram=$((bucket_total_ram + ram))
  done || exit 1
fi

# If ram size was not set, automatically scale it with the total amount of RAM required by the buckets.
if [ "$DIVAN_RAM_SIZE" -eq 0 ]; then
  DIVAN_RAM_SIZE="$bucket_total_ram"
# Static RAM assignation is designed so the user has no surprise, and keeps full control of the allocated resources.
# Thus, buckets are not allowed to exceed it.
elif [ "$DIVAN_RAM_SIZE" -lt "$bucket_total_ram" ]; then
  printf "the total amount of ram requested for the buckets (%s) overflows the amount of ram set in \
.database.resources.ramSize (%s) : either remove the .ramSize in resources for automatic allocation, or adjust \
your values to match\n" "$bucket_total_ram" "$DIVAN_RAM_SIZE" 1>&2
  exit 1
fi

# No static RAM amount was given for data, and no buckets were set (automatic scaling only works with default buckets).
if [ "$DIVAN_RAM_SIZE" -eq 0 ]; then
  printf "cannot compute ram size : either set a .database.resources.ramSize global attribute or define some \
buckets with ram for automatic attribution\n" 1>&2
  exit 1
# Minimum amount of RAM for data service is 1024Mb.
# https://docs.couchbase.com/server/current/install/sizing-general.html#about-couchbase-server-resources
elif [ "$DIVAN_RAM_SIZE" -lt 1024 ]; then
  printf "non valid ramSize value '%s' : must be greater than or equal to 1024\n" \
  "$DIVAN_RAM_SIZE" 1>&2
  exit 1
fi

sh "$DIVAN_SCRIPTS/utils/check_compaction_settings.sh" ".database.resources" || exit 1

purge_interval="$(
  jq -re ".database.resources.compaction.purgeInterval // empty" <"${DIVAN_CONFIG}"
)"

[ -z "$purge_interval" ] || {
  [ "$(echo "scale=0;${purge_interval}/0.04" | bc)" -ge 1 ] &&
    [ "$(echo "scale=0;${purge_interval}/60.001" | bc)" -lt 1 ]
} || {
  printf "non valid purgeInterval global value '%s' : should be a number between 0.04 and 60" \
    "$purge_interval" 1>&2
  exit 1
}

echo "DIVAN_RAM_SIZE=\"$DIVAN_RAM_SIZE\" DIVAN_FTS_RAM_SIZE=\"$DIVAN_FTS_RAM_SIZE\" DIVAN_INDEX_RAM_SIZE=\"$DIVAN_INDEX_RAM_SIZE\""
exit 0