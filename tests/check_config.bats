#!/usr/bin/env bats

setup() {
  export DIVAN_CONFIG="$BATS_TEST_DIRNAME/tmp.json"
}

teardown() {
  [ ! -f "$DIVAN_CONFIG" ] || rm "${DIVAN_CONFIG}"
  export DIVAN_CONFIG="/root/DIVAN-config/couchbase_config.json"
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with full config\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with no buckets\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {}
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with automatic allocation\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 1024
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m when username contains '@' character (not at start)\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 1024
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with secret credentials file\033[0m")"  {
  touch "$DIVAN_CONFIG"

  old_secret="$DIVAN_SECRET"
  export DIVAN_SECRET="$DIVAN_SECRET_FOLDER/valid_secret.json"
  touch "$DIVAN_SECRET"
  
  echo '{
    "username": "Secret_Admin",
    "password": "Secret_Password"
  }' > "$DIVAN_SECRET"
  
  echo '{
    "database": {
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 1024
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]

  rm "$DIVAN_SECRET"
  export DIVAN_SECRET="$old_secret"
}

@test "$(printf "\033[0;32mshould pass\033[0;37m when bucket name contains '_.%%-' characters\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "-my_users%web-site.com%": {
            "ramSize": 1024
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid bucket types\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase"
          },
          "bucket_2": {
            "ramSize": 256,
            "type": "ephemeral"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid priority option\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "priority": "high"
          },
          "bucket_2": {
            "ramSize": 256,
            "type": "couchbase",
            "priority": "low"
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "ephemeral",
            "priority": "high"
          },
          "bucket_4": {
            "ramSize": 256,
            "type": "ephemeral",
            "priority": "low"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}
@test "$(printf "\033[0;32mshould pass\033[0;37m with valid evictionPolicy option\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "evictionPolicy": "valueOnly"
          },
          "bucket_2": {
            "ramSize": 256,
            "type": "couchbase",
            "evictionPolicy": "fullEviction"
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "ephemeral",
            "evictionPolicy": "noEviction"
          },
          "bucket_4": {
            "ramSize": 256,
            "type": "ephemeral",
            "evictionPolicy": "nruEviction"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid flush option\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "flush": "true"
          },
          "bucket_2": {
            "ramSize": 256,
            "type": "couchbase",
            "flush": "false"
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase",
            "flush": true
          },
          "bucket_4": {
            "ramSize": 256,
            "type": "couchbase",
            "flush": false
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ]
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid purge interval on bucket level\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "purgeInterval": 0.04
          },
          "bucket_2": {
            "ramSize": 256,
            "type": "couchbase",
            "purgeInterval": 60
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "ephemeral",
            "purgeInterval": 0.007
          },
          "bucket_4": {
            "ramSize": 256,
            "type": "ephemeral",
            "purgeInterval": 60
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid purge interval on global level\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "purgeInterval": 30
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid compaction configuration on bucket level\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "compaction": {
              "threshold": {
                "percentage": 30
              }
            }
          },
          "bucket_2": {
            "ramSize": 256,
            "type": "couchbase",
            "compaction": {
              "threshold": {
                "size": 1024
              }
            }
          },
          "bucket_3": {
            "ramSize": 256,
            "type": "couchbase",
            "compaction": {
              "viewThreshold": {
                "percentage": 45
              }
            }
          },
          "bucket_4": {
            "ramSize": 256,
            "type": "couchbase",
            "compaction": {
              "threshold": {
                "size": 512
              }
            }
          },
          "bucket_5": {
            "ramSize": 256,
            "type": "couchbase",
            "compaction": {
              "threshold": {
                "size": 512,
                "percentage": 30
              },
              "viewThreshold": {
                "size": 512,
                "percentage": 30
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid compaction configuration on global level\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "percentage": 30
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 256
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "viewThreshold": {
            "percentage": 30
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "viewThreshold": {
            "size": 256
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid compaction timeframe on bucket level\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "compaction": {
              "threshold": {
                "size": 512
              },
              "abortOutside": true,
              "from": {
                "hour": 0,
                "minute": 0
              },
              "to": {
                "hour": 23,
                "minute": 59
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }
}

@test "$(printf "\033[0;32mshould pass\033[0;37m with valid compaction timeframe on global level\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 512
          },
          "abortOutside": true,
          "from": {
            "hour": 0,
            "minute": 0
          },
          "to": {
            "hour": 23,
            "minute": 59
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 0 ] || {
    echo "# $output"
    exit 1
  }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to export env variables\033[0m")"  {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  # shellcheck source=/dev/null
  output="$(sh "$DIVAN_SCRIPTS/check_config.sh")"
  exit_code=$?

  [ "$exit_code" -eq 0 ]

  eval "$output"

  [ "$DIVAN_USERNAME" = "admin@website" ]
  [ "$DIVAN_PASSWORD" = "password" ]
  [ "$DIVAN_RAM_SIZE" -eq 1024 ]
  [ "$DIVAN_INDEX_RAM_SIZE" -eq 256 ]
  [ "$DIVAN_FTS_RAM_SIZE" -eq 256 ]

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 2048
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  # shellcheck source=/dev/null
  output="$(sh "$DIVAN_SCRIPTS/check_config.sh")"
  exit_code=$?

  [ "$exit_code" -eq 0 ]

  eval "$output"

  [ "$DIVAN_USERNAME" = "admin@website" ]
  [ "$DIVAN_PASSWORD" = "password" ]
  [ "$DIVAN_RAM_SIZE" -eq 2048 ]
  [ "$DIVAN_INDEX_RAM_SIZE" -eq 256 ]
  [ "$DIVAN_FTS_RAM_SIZE" -eq 256 ]
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to prefer credentials in secret file\033[0m")" {
  touch "$DIVAN_CONFIG"

  old_secret="$DIVAN_SECRET"
  export DIVAN_SECRET="$DIVAN_SECRET_FOLDER/valid_secret.json"
  touch "$DIVAN_SECRET"

  echo '{
    "username": "Secret_Admin",
    "password": "Secret_Password"
  }' > "$DIVAN_SECRET"

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 1024
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  # shellcheck source=/dev/null
  output="$(sh "$DIVAN_SCRIPTS/check_config.sh")"
  exit_code=$?

  [ "$exit_code" -eq 0 ]

  eval "$output"

  [ "$DIVAN_USERNAME" = "Secret_Admin" ]
  [ "$DIVAN_PASSWORD" = "Secret_Password" ]

  rm "$DIVAN_SECRET"
  export DIVAN_SECRET="$old_secret"
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to fallback on credentials missing in secret file\033[0m")" {
  touch "$DIVAN_CONFIG"

  old_secret="$DIVAN_SECRET"
  export DIVAN_SECRET="$DIVAN_SECRET_FOLDER/valid_secret.json"
  touch "$DIVAN_SECRET"

  echo '{
    "username": "Secret_Admin"
  }' > "$DIVAN_SECRET"

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 1024
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  # shellcheck source=/dev/null
  output="$(sh "$DIVAN_SCRIPTS/check_config.sh")"
  exit_code=$?

  [ "$exit_code" -eq 0 ]

  eval "$output"

  [ "$DIVAN_USERNAME" = "Secret_Admin" ]
  [ "$DIVAN_PASSWORD" = "password" ]

  echo '{
    "password": "Secret_Password"
  }' > "$DIVAN_SECRET"

  # shellcheck source=/dev/null
  output="$(sh "$DIVAN_SCRIPTS/check_config.sh")"
  exit_code=$?

  [ "$exit_code" -eq 0 ]

  eval "$output"

  [ "$DIVAN_USERNAME" = "admin@website" ]
  [ "$DIVAN_PASSWORD" = "Secret_Password" ]

  rm "$DIVAN_SECRET"
  export DIVAN_SECRET="$old_secret"
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with empty config file\033[0m")" {
  touch "$DIVAN_CONFIG"
  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing .database.username" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with missing username\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{"database": {}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing .database.username" ]

  echo '{"database": {"username": null}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing .database.username" ]

  echo '{"database": {"username": ""}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing .database.username" ] || {
    printf "# %q\n" "$output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when username is longer than 128 characters\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "asdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklzasdfghjklz"
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = ".database.username should not be more than 128 character long" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when username starts with '@' character\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{"database": {"username": "@watashi"}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = ".database.username cannot start with '@'" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when username contains forbidden character\033[0m")" {
  touch "$DIVAN_CONFIG"

  for character in "(" ")" "<" ">" "," ";" ":" '\' '"' "/" "[" "]" "{" "}" "?" "="; do
    for name in "$(printf "%s" "name_${character}" | jq -Rs .)" \
    "$(printf "%s" "na_${character}_me" | jq -Rs .)" \
    "$(printf "%s" "${character}_name" | jq -Rs .)"; do
      printf "{\"database\": {\"username\": %s}}" "$name" > "$DIVAN_CONFIG"
      run sh "$DIVAN_SCRIPTS/check_config.sh"
      [ "$status" -eq 1 ]
      [ "$output" = "$(printf ".database.username cannot contain character '%s'" "$character")" ]
    done
  done
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with missing password\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{"database": {"username": "Administrator"}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing .database.password" ]

  echo '{"database": {"username": "Administrator", "password": null}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing .database.password" ]

  echo '{"database": {"username": "Administrator", "password": ""}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing .database.password" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when password is shorter than 6 characters\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{"database": {"username": "Administrator", "password": "pass"}}' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = ".database.password should be at least 6 character long" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with indexRamSize lower than 256\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": -1
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid indexRamSize value '-1' : must be greater than or equal to 256" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with ftsRamSize lower than 256\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": -1
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid ftsRamSize value '-1' : must be greater than or equal to 256" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with ramSize lower than 1024\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 10
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid ramSize value '10' : must be greater than or equal to 1024" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with bucket with less than 100Mb allocated ram\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 90
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid ramSize value '90' for bucket bucket_1 : must be a number greater than or equal to 100" ]
}


@test "$(printf "\033[0;31mshould fail\033[0;37m when sum of buckets allocated ram exceeds static allocation value\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 1536
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "the total amount of ram requested for the buckets (1536) overflows the amount of ram set in .database.resources.ramSize (1024) : either remove the .ramSize in resources for automatic allocation, or adjust your values to match" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with automatic allocation when buckets dont ask for enough ram\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 128
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid ramSize value '128' : must be greater than or equal to 1024" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid bucket type\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "type": "hello"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid type value 'hello' for bucket bucket_1 : only 'ephemeral' and 'couchbase' are allowed" ]
}


@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid priority value\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "priority": "hello"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid priority value 'hello' for bucket bucket_1 : only 'low' and 'high' are allowed" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid evictionPolicy value\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral",
            "evictionPolicy": "valueOnly"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid evictionPolicy value 'valueOnly' for bucket bucket_1 : only 'noEviction' and 'nruEviction' are allowed for ephemeral buckets" ]

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "ephemeral",
            "evictionPolicy": "fullEviction"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid evictionPolicy value 'fullEviction' for bucket bucket_1 : only 'noEviction' and 'nruEviction' are allowed for ephemeral buckets" ]

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "evictionPolicy": "noEviction"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid evictionPolicy value 'noEviction' for bucket bucket_1 : only 'valueOnly' and 'fullEviction' are allowed for couchbase buckets" ]

  echo '{
    "database": {
      "username": "admin@website",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 256,
            "type": "couchbase",
            "evictionPolicy": "nruEviction"
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid evictionPolicy value 'nruEviction' for bucket bucket_1 : only 'valueOnly' and 'fullEviction' are allowed for couchbase buckets" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when bucket has non valid characters in its name\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1??#": {
            "ramSize": 128
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid bucket name 'bucket_1??#' : name can only contain alphanumeric characters, '.', '-', '_' and '%'" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when bucket name is longer than 100 characters\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "abcdefhijkabcdefhijkabcdefhijkabcdefhijkabcdefhijkabcdefhijkabcdefhijkabcdefhijkabcdefhijkabcdefhijkabcdefhijk": {
            "ramSize": 128
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "bucket name must be no more than 100 characters" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid flush option\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "flush": 0
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid flush value '0' for bucket bucket_1 : should be a boolean" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid purge interval value\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "purgeInterval": 0.005
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid purgeInterval value '0.005' for bucket bucket_1 : should be a number between 0.04 and 60" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "purgeInterval": 61
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid purgeInterval value '61' for bucket bucket_1 : should be a number between 0.04 and 60" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "type": "ephemeral",
            "purgeInterval": 0.005
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid purgeInterval value '0.005' for bucket bucket_1 : should be a number between 0.007 and 60" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "type": "ephemeral",
            "purgeInterval": 61
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid purgeInterval value '61' for bucket bucket_1 : should be a number between 0.007 and 60" ] || {
    echo "# $output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid compaction thresholds\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "percentage": 1
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction threshold percentage value '1' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "percentage": 101
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction threshold percentage value '101' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "size": -1
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction threshold size value '-1' : should be a number greater than or equal to 1" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "viewThreshold": {
                "percentage": 1
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction view threshold percentage value '1' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "viewThreshold": {
                "percentage": 101
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction view threshold percentage value '101' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "viewThreshold": {
                "size": -1
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction view threshold size value '-1' : should be a number greater than or equal to 1" ] || {
    echo "# $output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when compaction timeframe is set without compaction settings\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "from": {
                "hour": 0,
                "minute": 0
              },
              "to": {
                "hour": 2,
                "minute": 0
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : cannot set compaction interval if no compaction threshold is set" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when missing compaction timeframe settings\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "size": 10
              },
              "from": {
                "minute": 0
              },
              "to": {
                "hour": 2,
                "minute": 0
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : missing compaction start hour : compaction interval requires full setup to run" ]

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "size": 10
              },
              "from": {
                "hour": 0
              },
              "to": {
                "hour": 2,
                "minute": 0
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : missing compaction start minute : compaction interval requires full setup to run" ]

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "size": 10
              },
              "from": {
                "hour": 0,
                "minute": 0
              },
              "to": {
                "minute": 0
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : missing compaction end hour : compaction interval requires full setup to run" ]

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "size": 10
              },
              "from": {
                "hour": 0,
                "minute": 0
              },
              "to": {
                "hour": 0
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : missing compaction end minute : compaction interval requires full setup to run" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when compaction is set on ephemeral bucket\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "type": "ephemeral",
            "compaction": {
              "threshold": {
                "size": 10
              }
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "compaction is only available for couchbase buckets, for bucket bucket_1" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when abortOutside is set without compaction timeframe\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "size": 10
              },
              "abortOutside": true
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : cannot set compaction abortOutside if no compaction timeframe is set" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid abortOutside value\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "threshold": {
                "size": 10
              },
              "from": {
                "hour": 2,
                "minute": 0
              },
              "to": {
                "hour": 6,
                "minute": 0
              },
              "abortOutside": 123
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction abortOutside value '123' : should be a boolean" ] || \
  { printf "# %s\n" "$output" >&3; exit 1; }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid parallelCompaction value\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "buckets": {
          "bucket_1": {
            "ramSize": 128,
            "compaction": {
              "parallelCompaction": 123
            }
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "error in compaction settings for bucket bucket_1 : non valid compaction parallelCompaction value '123' : should be a boolean" ] || \
  { printf "# %s\n" "$output" >&3; exit 1; }
}


@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid purge interval value on global level\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "purgeInterval": 0.005
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid purgeInterval global value '0.005' : should be a number between 0.04 and 60" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "purgeInterval": 61
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid purgeInterval global value '61' : should be a number between 0.04 and 60" ] || {
    echo "# $output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid compaction thresholds on global level\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "percentage": 1
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction threshold percentage value '1' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "percentage": 101
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction threshold percentage value '101' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": -1
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction threshold size value '-1' : should be a number greater than or equal to 1" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "viewThreshold": {
            "percentage": 1
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction view threshold percentage value '1' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "viewThreshold": {
            "percentage": 101
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction view threshold percentage value '101' : should be a number between 2 and 100" ] || {
    echo "# $output" >&3
    exit 1
  }

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "viewThreshold": {
            "size": -1
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction view threshold size value '-1' : should be a number greater than or equal to 1" ] || {
    echo "# $output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when compaction timeframe is set without compaction settings on global level\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "from": {
            "hour": 0,
            "minute": 0
          },
          "to": {
            "hour": 2,
            "minute": 0
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "cannot set compaction interval if no compaction threshold is set" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when missing compaction timeframe settings on global level\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 10
          },
          "from": {
            "minute": 0
          },
          "to": {
            "hour": 2,
            "minute": 0
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing compaction start hour : compaction interval requires full setup to run" ]

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 10
          },
          "from": {
            "hour": 0
          },
          "to": {
            "hour": 2,
            "minute": 0
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing compaction start minute : compaction interval requires full setup to run" ]

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 10
          },
          "from": {
            "hour": 0,
            "minute": 0
          },
          "to": {
            "minute": 0
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing compaction end hour : compaction interval requires full setup to run" ]

  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 10
          },
          "from": {
            "hour": 0,
            "minute": 0
          },
          "to": {
            "hour": 0
          }
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "missing compaction end minute : compaction interval requires full setup to run" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m when abortOutside is set without compaction timeframe on global level\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 10
          },
          "abortOutside": true
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "cannot set compaction abortOutside if no compaction timeframe is set" ]
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid abortOutside value on global level\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "threshold": {
            "size": 10
          },
          "from": {
            "hour": 2,
            "minute": 0
          },
          "to": {
            "hour": 6,
            "minute": 0
          },
          "abortOutside": 123
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction abortOutside value '123' : should be a boolean" ] || \
  { printf "# %s\n" "$output" >&3; exit 1; }
}

@test "$(printf "\033[0;31mshould fail\033[0;37m with non valid parallelCompaction value on global level\033[0m")" {
  touch "$DIVAN_CONFIG"
  echo '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "indexRamSize": 256,
        "ftsRamSize": 256,
        "ramSize": 1024,
        "compaction": {
          "parallelCompaction": 123
        }
      }
    }
  }' > "$DIVAN_CONFIG"

  run sh "$DIVAN_SCRIPTS/check_config.sh"

  [ "$status" -eq 1 ]
  [ "$output" = "non valid compaction parallelCompaction value '123' : should be a boolean" ] || \
  { printf "# %s\n" "$output" >&3; exit 1; }
}