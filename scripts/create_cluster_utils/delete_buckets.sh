#!/bin/sh

eval "$(sh "$DIVAN_SCRIPTS/utils/safe_mode.sh")"

[ "$SAFE_MODE" -eq 0 ] || exit 0

username="$1"
password="$2"

# Get current buckets, if any.
current_buckets="$(curl -s -u "$username":"$password" http://127.0.0.1:8091/pools/default/buckets)"
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

update_cmd=""

if [ "$bucket_count" -gt 0 ]; then
  for bucket_name in $(jq -re '.database.resources.buckets | keys | join(" ")' <"${DIVAN_CONFIG}"); do
    bucket_data="$(jq -re ".database.resources.buckets[\"${bucket_name}\"] // empty" <"${DIVAN_CONFIG}")"
    bucket_eviction_policy="$(echo "$bucket_data" | jq -re ".evictionPolicy // empty")"
    bucket_type="$(echo "$bucket_data" | jq -re ".type // empty")"

    if [ -z "$bucket_type" ]; then
      bucket_type="couchbase"
    fi

    delete_bucket_cmd="$(
      sh "$DIVAN_SCRIPTS/create_buckets_utils/should_bucket_update.sh" \
      "$bucket_name" "$bucket_type" "$bucket_eviction_policy" "$current_buckets_count" "$current_buckets"
    )" || {
      printf "%s" "$delete_bucket_cmd" 1>&2
      exit 1
    }

    eval "$delete_bucket_cmd"

    [ -n "$DELETE_ACTION" ] && {
      if [ -z "$update_cmd" ]; then
        update_cmd="$DELETE_ACTION"
      else
        update_cmd="$update_cmd && $DELETE_ACTION"
      fi
    }
  done
fi

# Remove all undeclared buckets (unsafe mode only)
for old_bucket in $current_buckets; do
  name="$(echo "$old_bucket" | jq -re ".name")"
  if [ "$bucket_count" -gt 0 ]; then
    remove=1
    for bucket_name in $(jq -re '.database.resources.buckets | keys | join(" ")' <"${DIVAN_CONFIG}"); do
      [ "$bucket_name" != "$name" ] || {
        remove=0
        break
      }
    done

    [ "$remove" -eq 0 ] || {
      remove_cmd="/opt/couchbase/bin/couchbase-cli bucket-delete -c 127.0.0.1 \
--username '$DIVAN_USERNAME' --password '$DIVAN_PASSWORD' \
--bucket '$name'"

      if [ -z "$update_cmd" ]; then
        update_cmd="$remove_cmd"
      else
        update_cmd="$update_cmd && $remove_cmd"
      fi
    }
  else
    remove_cmd="/opt/couchbase/bin/couchbase-cli bucket-delete -c 127.0.0.1 \
--username '$DIVAN_USERNAME' --password '$DIVAN_PASSWORD' \
--bucket '$name'"

    if [ -z "$update_cmd" ]; then
      update_cmd="$remove_cmd"
    else
      update_cmd="$update_cmd && $remove_cmd"
    fi
  fi
done

[ -n "$update_cmd" ] || exit 0

output="$(eval "$update_cmd")" || {
  printf "ERROR : while cleaning buckets : %s\n" "$output" 1>&2
  exit 1
}

exit 0