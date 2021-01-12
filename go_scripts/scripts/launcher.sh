#!/bin/sh

if [ "$(uname)" = "Linux" ]; then
  systemctl start couchbase-server
elif [ "$(uname)" = "Darwin" ]; then
  output="$(open -a "Couchbase Server")"
  status="$?"

  [ "$status" -gt 1 ] && {
    printf "%s" "$output"
    exit $status
  }

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
fi

exit 0