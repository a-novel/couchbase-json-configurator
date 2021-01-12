#!/bin/sh

if [ "$(uname)" = "Linux" ]; then
  systemctl stop couchbase-server || exit 1
  rm -rf /opt/couchbase || exit 1
elif [ "$(uname)" = "Darwin" ]; then
  output="$(osascript -e 'quit app "Couchbase Server"')"
  status="$?"
  echo "$status"
  [ "$status" -gt 2 ] && {
    printf "%s" "$output"
    exit $status
  }

  rm -rf ~/"Library/Application Support/Couchbase" || exit 2
  rm -rf ~/"Library/Application Support/membase" || exit 2
  rm -rf ~/Library/Python/couchbase-py || exit 2
fi

exit 0