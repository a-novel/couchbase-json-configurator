#!/usr/bin/env bats

start() {
  load_data="$(sh "$DIVAN_SCRIPTS/check_config.sh")" || {
    printf "%s" "$load_data" 1>&2
    exit 1
  }

  eval "$load_data"
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to create cluster on dedi\033[0m\033[0;37mcated port \033[0;95m───────────╮\033[0m")" {
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ramSize": 2048,
        "ftsRamSize": 512,
        "indexRamSize": 512
      }
    }
  }' > "$DIVAN_CONFIG"

  start

  sh "$DIVAN_SCRIPTS/create_cluster.sh" 1>/dev/null || {
    printf "# %q\n" "$output" >&3
    exit 1
  }

  elapsed=0
  status=1

  until [ "$status" -eq 0 ] || [ "$elapsed" -eq 10 ]; do
    run /opt/couchbase/bin/couchbase-cli server-info -c 127.0.0.1 --username "Administrator" --password "password"
    sleep 1
    elapsed=$((elapsed + 1))
  done

  [ "$status" -eq 0 ] || {
    printf "# %s\n" "$output" >&3
    exit 1
  }

  [ "$(echo "$output" | jq -re ".hostname // empty")" = "127.0.0.1:8091" ] || {
    printf "# wrong value '%s' for hostname : expected 127.0.0.1:8091\n" \
    "$(echo "$output" | jq -re ".hostname // empty")" >&3
    exit 1
  }
  [ "$(echo "$output" | jq -re ".memoryQuota // empty")" -eq 2048 ] || {
    printf "# wrong value '%s' for memoryQuota : expected 2048\n" \
    "$(echo "$output" | jq -re ".memoryQuota // empty")" >&3
    exit 1
  }
  [ "$(echo "$output" | jq -re ".indexMemoryQuota // empty")" -eq 512 ] || {
    printf "# wrong value '%s' for indexMemoryQuota : expected 512\n" \
    "$(echo "$output" | jq -re ".indexMemoryQuota // empty")" >&3
    exit 1
  }
  [ "$(echo "$output" | jq -re ".ftsMemoryQuota // empty")" -eq 512 ] || {
    printf "# wrong value '%s' for ftsMemoryQuota : expected 512\n" \
    "$(echo "$output" | jq -re ".ftsMemoryQuota // empty")" >&3
    exit 1
  }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to update cluster when on\033[0m\033[0;37me is already running \033[0;95m─╯\033[0m")" {
  echo '{
    "database": {
      "username": "admin@database",
      "password": "password2",
      "resources": {
        "ramSize": 1024,
        "ftsRamSize": 256,
        "indexRamSize": 256
      }
    }
  }' > "$DIVAN_CONFIG"

  start

  sh "$DIVAN_SCRIPTS/create_cluster.sh" 1>/dev/null || {
    printf "# %q\n" "$output" >&3
    exit 1
  }

  run /opt/couchbase/bin/couchbase-cli server-info -c 127.0.0.1 --username "Administrator" --password "password"
  [ "$status" -gt 0 ]

  run /opt/couchbase/bin/couchbase-cli server-info -c 127.0.0.1 --username "admin@database" --password "password2"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -re ".hostname // empty")" = "127.0.0.1:8091" ]
  [ "$(echo "$output" | jq -re ".ftsMemoryQuota // empty")" -eq 256 ]
  [ "$(echo "$output" | jq -re ".indexMemoryQuota // empty")" -eq 256 ]
  [ "$(echo "$output" | jq -re ".memoryQuota // empty")" -eq 1024 ]
}