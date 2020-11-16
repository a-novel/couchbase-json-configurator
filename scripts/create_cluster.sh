#!/bin/sh

# Create the cluster for the application.

# Waiting for UI to be available, since upcoming operations cannot occur otherwise.
printf "→ \033[0;33mWaiting for Web UI \033[0m"

# We set a default timeout of 20 seconds, since cluster should be up by then.
elapsed=0
# Curl request to Couchbase API should return with status 200, once up.
until [ "$(curl -sL -w '%{http_code}' http://127.0.0.1:8091/ui/index.html -o /dev/null)" = "200" ] || [ "$elapsed" -ge 20 ]; do
  printf '='
  elapsed=$((elapsed + 1))
  sleep 1
done

# Timed out and UI is still not available.
if [ $elapsed -eq 20 ] && [ "$(curl -sL -w '%{http_code}' http://127.0.0.1:8091/ui/index.html -o /dev/null)" != "200" ]; then
  printf "\r\033[K \033[0;31mTimeout error : code %s\033[0m" "$(curl -sL -w '%{http_code}' http://127.0.0.1:8091/ui/index.html -o /dev/null)"
  exit 1
fi

printf "\r\033[K Web UI available at \033[0;36mhttp://127.0.0.1:8091/ui/index.html\033[0m\n"

# Fetch old credentials if any, since we'll need them if we get to update an existing cluster.
old_username=""
old_password=""

# Divan image automatically creates a duplicate of current keys once cluster is set up.
if [ -f "${DIVAN_CONFIG_FOLDER}/old.json" ]; then
  old_username="$(jq -re ".username // empty" <"${DIVAN_CONFIG_FOLDER}/old.json")"
  old_password="$(jq -re ".password // empty" <"${DIVAN_CONFIG_FOLDER}/old.json")"
fi

compaction_threshold_percentage="$(
  jq -re ".database.resources.compaction.threshold.percentage // empty" <"${DIVAN_CONFIG}"
)"

compaction_threshold_size="$(
  jq -re ".database.resources.compaction.threshold.size // empty" <"${DIVAN_CONFIG}"
)"

view_compaction_threshold_percentage="$(
  jq -re ".database.resources.compaction.viewThreshold.percentage // empty" <"${DIVAN_CONFIG}"
)"

view_compaction_threshold_size="$(
  jq -re ".database.resources.compaction.viewThreshold.size // empty" <"${DIVAN_CONFIG}"
)"

compaction_from_hour="$(
  jq -re ".database.resources.compaction.from.hour // empty" <"${DIVAN_CONFIG}"
)"

compaction_from_minute="$(
  jq -re ".database.resources.compaction.from.minute // empty" <"${DIVAN_CONFIG}"
)"

compaction_to_hour="$(
  jq -re ".database.resources.compaction.to.hour // empty" <"${DIVAN_CONFIG}"
)"

compaction_to_minute="$(
  jq -re ".database.resources.compaction.to.minute // empty" <"${DIVAN_CONFIG}"
)"

abort_outside="$(
  jq -re ".database.resources.compaction.abortOutside // empty" <"${DIVAN_CONFIG}"
)"

parallel_compaction="$(
  jq -re ".database.resources.compaction.parallelCompaction // empty" <"${DIVAN_CONFIG}"
)"

purge_interval="$(
  jq -re ".database.resources.purgeInterval // empty" <"${DIVAN_CONFIG}"
)"

[ -n "$parallel_compaction" ] || parallel_compaction="false"

curl_string=""

curl_string="$(sh "$DIVAN_SCRIPTS/utils/set_compaction.sh" "http://127.0.0.1:8091/controller/setAutoCompaction" \
"$compaction_threshold_percentage" "$compaction_threshold_size" \
"$view_compaction_threshold_percentage" "$view_compaction_threshold_size" \
"$compaction_from_hour" "$compaction_from_minute" \
"$compaction_to_hour" "$compaction_to_minute" \
"$abort_outside" "$purge_interval" "$parallel_compaction" "true")" || {
  echo "$curl_string" 1>&2
  exit 1
}

# If a cluster is already up, a request to the server-list with right credentials will return a 0 exit status
# (OK status). If no cluster is up, command will fail.
if /opt/couchbase/bin/couchbase-cli server-list -c 127.0.0.1 --username "$old_username" --password "$old_password"; then
  output="$(sh "$DIVAN_SCRIPTS/create_cluster_utils/delete_buckets.sh" "$old_username" "$old_password")" || {
    echo "ERROR cleaning old buckets: $output" 1>&2
    exit 1
  }

  /opt/couchbase/bin/couchbase-cli setting-cluster -c 127.0.0.1 \
--username "$old_username" --password "$old_password" \
--cluster-username "${DIVAN_USERNAME}" \
--cluster-password "${DIVAN_PASSWORD}" \
--cluster-ramsize "$DIVAN_RAM_SIZE" \
--cluster-fts-ramsize "$DIVAN_FTS_RAM_SIZE" \
--cluster-index-ramsize "$DIVAN_INDEX_RAM_SIZE"
else
  /opt/couchbase/bin/couchbase-cli cluster-init -c 127.0.0.1 \
--cluster-username "${DIVAN_USERNAME}" \
--cluster-password "${DIVAN_PASSWORD}" \
--cluster-ramsize "$DIVAN_RAM_SIZE" \
--cluster-fts-ramsize "$DIVAN_FTS_RAM_SIZE" \
--cluster-index-ramsize "$DIVAN_INDEX_RAM_SIZE" \
--services data,query,index,fts
fi

[ -n "$curl_string" ] && eval "$curl_string"

# Save current config for later re-deployments.
[ -f "${DIVAN_CONFIG_FOLDER}/old.json" ] || touch "${DIVAN_CONFIG_FOLDER}/old.json"
echo "{\"username\": \"$DIVAN_USERNAME\", \"password\": \"$DIVAN_PASSWORD\"}" > "${DIVAN_CONFIG_FOLDER}/old.json"
exit 0