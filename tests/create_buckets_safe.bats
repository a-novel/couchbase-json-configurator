#!/usr/bin/env bats

setup() {
  export ENV='production'
}

teardown() {
  export ENV=''
}

@test "$(printf "\033[0;37msafe mode should be on\033[0m")" {
  eval "$(sh "$DIVAN_SCRIPTS/utils/safe_mode.sh")"

  [ "$SAFE_MODE" -eq 1 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with no buckets\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ramSize": 1024,
        "ftsRamSize": 256,
        "indexRamSize": 256
      }
    }
  }'

  [ "$status" -eq 0 ] || {
    printf "# %s\n" "$output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to create new buckets \033[0;95m───\033[0m\033[0;95m─────────────────────────────────────────╮\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral"
          },
          "bucket_2": {
            "ramSize": 512,
            "evictionPolicy": "fullEviction"
          }
        }
      }
    }
  }'

  [ "$status" -eq 0 ] || {
    printf "# %s\n" "$output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to update old buckets\033[0m                                             \033[0;95m|\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral"
          },
          "bucket_2": {
            "ramSize": 1024,
            "evictionPolicy": "valueOnly",
            "flush": true
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase"
          }
        }
      }
    }
  }'

  [ "$status" -eq 0 ] || {
    printf "# %s\n" "$output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when trying to change bucket type\033[0m                                \033[0;95m|\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase"
          },
          "bucket_2": {
            "ramSize": 1024,
            "evictionPolicy": "valueOnly",
            "flush": true
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase"
          }
        }
      }
    }
  }'

  [ "$status" -eq 1 ]
  [ "$output" = "ERROR : bucket type cannot be changed, in bucket bucket_1 : \
please revert it to ephemeral, or run the image with FORCE_UNSAFE env variable (please note \
it will result in the loss of the entire bucket data)." ] || {
    printf "# %q\n" "$output" >&3
    exit 1
  }

  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral"
          },
          "bucket_2": {
            "ramSize": 1024,
            "evictionPolicy": "valueOnly",
            "flush": true
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase"
          }
        }
      }
    }
  }'

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when trying to change bucket evi\033[0m\033[0;37mctionPolicy for ephemeral bucket \033[0;95m|\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral",
            "evictionPolicy": "nruEviction"
          },
          "bucket_2": {
            "ramSize": 1024,
            "evictionPolicy": "valueOnly",
            "flush": true
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase"
          }
        }
      }
    }
  }'

  [ "$status" -eq 1 ]
  [ "$output" = "ERROR : eviction policy cannot be changed for ephemeral buckets, in bucket bucket_1 : \
please revert it to noEviction, or run the image with FORCE_UNSAFE env variable (please note \
it will result in the loss of the entire bucket data)." ] || {
    printf "# %q\n" "$output" >&3
    exit 1
  }

  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral"
          },
          "bucket_2": {
            "ramSize": 1024,
            "evictionPolicy": "valueOnly",
            "flush": true
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase"
          }
        }
      }
    }
  }'

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when trying to remove bu\033[0m\033[0;37mcket \033[0;95m────────────────────────────────────╯\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_2": {
            "ramSize": 1024,
            "evictionPolicy": "valueOnly",
            "flush": true
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase"
          }
        }
      }
    }
  }'

  [ "$status" -eq 1 ]
  [ "$output" = "ERROR : you cannot remove bucket bucket_1 in safe mode" ] || {
    printf "# %q\n" "$output" >&3
    exit 1
  }

  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "ramSize": 2048,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral"
          },
          "bucket_2": {
            "ramSize": 1024,
            "evictionPolicy": "valueOnly",
            "flush": true
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase"
          }
        }
      }
    }
  }'

  [ "$status" -eq 0 ]
}