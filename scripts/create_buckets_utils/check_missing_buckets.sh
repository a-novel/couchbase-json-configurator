#!/bin/sh

if [ "$SAFE_MODE" -eq 1 ]; then
  for old_bucket in $1; do
    found=0
    name="$(echo "$old_bucket" | jq -re ".name")"

    for bucket_name in $(jq -re '.database.resources.buckets | keys | join(" ")' <"${DIVAN_CONFIG}"); do
      [ "$bucket_name" = "$name" ] && found=1
    done

    [ "$found" -eq 1 ] || {
      printf "ERROR : you cannot remove bucket %s in safe mode\n" "$name" 1>&2
      exit 1
    }
  done
fi

exit 0