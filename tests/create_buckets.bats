#!/usr/bin/env bats

clean() {
  sh "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
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

  sh "$BATS_TEST_DIRNAME/utils/wait_for_match.sh"
}

@test "$(printf "\033[0;37msafe mode should be off\033[0m")" {
  eval "$(sh "$DIVAN_SCRIPTS/utils/safe_mode.sh")"

  [ "$SAFE_MODE" -eq 0 ] || {
    echo "# unexpected safe mode value '$SAFE_MODE' : should be 0 (from command $(sh "$DIVAN_SCRIPTS/utils/safe_mode.sh"))" >&3
    exit 1
  }
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
  
  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/wait_for_match.sh"
  
  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to remove unused bucket\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ramSize": 1024,
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 256
          }
        }
      }
    }
  }' 
  
  [ "$status" -eq 0 ] || { printf "# %q\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/wait_for_match.sh" '{"name": "bucket_1", "check": []}'
  
  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ramSize": 1024,
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "buckets": {}
      }
    }
  }'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/wait_for_match.sh"

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to update bucket ram\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ramSize": 1024,
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 100
          }
        }
      }
    }
  }'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/wait_for_match.sh" \
  "{\"name\": \"bucket_1\", \"check\": [{\"key\": \".quota.ram\", \"value\": $((100 * 1048576))}]}"

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
    "database": {
      "username": "Administrator",
      "password": "password",
      "resources": {
        "ramSize": 1024,
        "ftsRamSize": 256,
        "indexRamSize": 256,
        "buckets": {
          "bucket_1": {
            "ramSize": 256
          }
        }
      }
    }
  }'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/wait_for_match.sh" \
  "{\"name\": \"bucket_1\", \"check\": [{\"key\": \".quota.ram\", \"value\": $((256 * 1048576))}]}"

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct type values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral"
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".bucketType", "value": "membase"}]}
  ]' \
  '[
    {"name": "bucket_1", "check": [{"key": ".bucketType", "value": "ephemeral"}]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct purgeInterval values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral"
    },
    "bucket_2": {
      "ramSize": 100
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral",
      "purgeInterval": 10.5
    },
    "bucket_2": {
      "ramSize": 100,
      "purgeInterval": 30
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".purgeInterval", "value": 3}]},
    {"name": "bucket_2", "check": [{"key": ".purgeInterval", "value": ""}]}
  ]' \
  '[
    {"name": "bucket_1", "check": [{"key": ".purgeInterval", "value": "10.5"}]},
    {"name": "bucket_2", "check": [{"key": ".purgeInterval", "value": "30"}]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct priority values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral"
    },
    "bucket_2": {
      "ramSize": 100
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral",
      "priority": "high"
    },
    "bucket_2": {
      "ramSize": 100,
      "priority": "high"
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".threadsNumber", "value": 3}]},
    {"name": "bucket_2", "check": [{"key": ".threadsNumber", "value": 3}]}
  ]' \
  '[
    {"name": "bucket_1", "check": [{"key": ".threadsNumber", "value": 8}]},
    {"name": "bucket_2", "check": [{"key": ".threadsNumber", "value": 8}]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct evictionPolicy values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral"
    },
    "bucket_2": {
      "ramSize": 100
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral",
      "evictionPolicy": "nruEviction"
    },
    "bucket_2": {
      "ramSize": 100,
      "evictionPolicy": "fullEviction"
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".evictionPolicy", "value": "noEviction"}]},
    {"name": "bucket_2", "check": [{"key": ".evictionPolicy", "value": "valueOnly"}]}
  ]' \
  '[
    {"name": "bucket_1", "check": [{"key": ".evictionPolicy", "value": "nruEviction"}]},
    {"name": "bucket_2", "check": [{"key": ".evictionPolicy", "value": "fullEviction"}]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct flush values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral"
    },
    "bucket_2": {
      "ramSize": 100
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "type": "ephemeral",
      "flush": true
    },
    "bucket_2": {
      "ramSize": 100,
      "flush": true
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".controllers.flush", "value": ""}]},
    {"name": "bucket_2", "check": [{"key": ".controllers.flush", "value": ""}]}
  ]' \
  '[
    {"name": "bucket_1", "check": [{"key": ".controllers.flush", "value": "/pools/default/buckets/bucket_1/controller/doFlush"}]},
    {"name": "bucket_2", "check": [{"key": ".controllers.flush", "value": "/pools/default/buckets/bucket_2/controller/doFlush"}]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct compaction thresholds values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100
    },
    "bucket_2": {
      "ramSize": 100,
      "purgeInterval": 3
    },
    "bucket_3": {
      "ramSize": 100,
      "purgeInterval": 3
    },
    "bucket_4": {
      "ramSize": 100,
      "purgeInterval": 3
    },
    "bucket_5": {
      "ramSize": 100,
      "purgeInterval": 3
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "percentage": 80,
          "size": 512
        },
        "viewThreshold": {
          "percentage": 40,
          "size": 256
        }
      }
    },
    "bucket_2": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "percentage": 80
        }
      }
    },
    "bucket_3": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "size": 512
        }
      }
    },
    "bucket_4": {
      "ramSize": 100,
      "compaction": {
        "viewThreshold": {
          "percentage": 40
        }
      }
    },
    "bucket_5": {
      "ramSize": 100,
      "compaction": {
        "viewThreshold": {
          "size": 256
        }
      }
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".autoCompactionSettings", "value": ""}]},
    {"name": "bucket_2", "check": [{"key": ".autoCompactionSettings.databaseFragmentationThreshold.percentage", "value": "undefined"}]},
    {"name": "bucket_3", "check": [{"key": ".autoCompactionSettings.databaseFragmentationThreshold.size", "value": "undefined"}]},
    {"name": "bucket_4", "check": [{"key": ".autoCompactionSettings.viewFragmentationThreshold.percentage", "value": "undefined"}]},
    {"name": "bucket_5", "check": [{"key": ".autoCompactionSettings.viewFragmentationThreshold.size", "value": "undefined"}]}
  ]' \
  "[
    {\"name\": \"bucket_1\", \"check\": [
      {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.percentage\", \"value\": 80},
      {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.size\", \"value\": $((512 * 1048576))},
      {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.percentage\", \"value\": 40},
      {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.size\", \"value\": $((256 * 1048576))}
    ]},
    {\"name\": \"bucket_2\", \"check\": [{\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.percentage\", \"value\": 80}]},
    {\"name\": \"bucket_3\", \"check\": [{\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.size\", \"value\": $((512 * 1048576))}]},
    {\"name\": \"bucket_4\", \"check\": [{\"key\": \".autoCompactionSettings.viewFragmentationThreshold.percentage\", \"value\": 40}]},
    {\"name\": \"bucket_5\", \"check\": [{\"key\": \".autoCompactionSettings.viewFragmentationThreshold.size\", \"value\": $((256 * 1048576))}]}
  ]"

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct compaction timeframe values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "size": 512
        }
      }
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "size": 512
        },
        "from": {
          "hour": 2,
          "minute": 30
        },
        "to": {
          "hour": 6,
          "minute": 45
        }
      }
    }
  }' \
  '[
    {"name": "bucket_1", "check": [
      {"key": ".autoCompactionSettings.allowedTimePeriod.fromHour", "value": ""},
      {"key": ".autoCompactionSettings.allowedTimePeriod.fromMinute", "value": ""},
      {"key": ".autoCompactionSettings.allowedTimePeriod.toHour", "value": ""},
      {"key": ".autoCompactionSettings.allowedTimePeriod.toMinute", "value": ""}
    ]}
  ]' \
  '[
    {"name": "bucket_1", "check": [
      {"key": ".autoCompactionSettings.allowedTimePeriod.fromHour", "value": 2},
      {"key": ".autoCompactionSettings.allowedTimePeriod.fromMinute", "value": 30},
      {"key": ".autoCompactionSettings.allowedTimePeriod.toHour", "value": 6},
      {"key": ".autoCompactionSettings.allowedTimePeriod.toMinute", "value": 45}
    ]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct compaction abortOutside values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "size": 512
        },
        "from": {
          "hour": 2,
          "minute": 0
        },
        "to": {
          "hour": 6,
          "minute": 0
        }
      }
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "size": 512
        },
        "from": {
          "hour": 2,
          "minute": 0
        },
        "to": {
          "hour": 6,
          "minute": 0
        },
        "abortOutside": true
      }
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".autoCompactionSettings.allowedTimePeriod.abortOutside", "value": ""}]}
  ]' \
  '[
    {"name": "bucket_1", "check": [{"key": ".autoCompactionSettings.allowedTimePeriod.abortOutside", "value": "true"}]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to have correct compaction parallelCompaction values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/duf_test.sh" \
  '{
    "bucket_1": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "size": 512
        }
      }
    }
  }' \
  '{
    "bucket_1": {
      "ramSize": 100,
      "compaction": {
        "threshold": {
          "size": 512
        },
        "parallelCompaction": true
      }
    }
  }' \
  '[
    {"name": "bucket_1", "check": [{"key": ".autoCompactionSettings.parallelDBAndViewCompaction", "value": ""}]}
  ]' \
  '[
    {"name": "bucket_1", "check": [{"key": ".autoCompactionSettings.parallelDBAndViewCompaction", "value": "true"}]}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to create buckets with unique parallelCompaction values\033[0m")" {
  run "$BATS_TEST_DIRNAME/utils/prepare_buckets.sh" '{
  "database": {
    "username": "Administrator",
    "password": "password",
    "resources": {
      "ramSize": 1024,
      "ftsRamSize": 256,
      "indexRamSize": 256,
      "buckets": {
         "bucket_1": {
          "ramSize": 100,
          "compaction": {
            "threshold": {
              "percentage": 50
            },
            "parallelCompaction": true
          }
        },
        "bucket_2": {
          "ramSize": 100,
          "compaction": {
            "threshold": {
              "percentage": 50
            },
            "parallelCompaction": false
          }
        },
        "bucket_3": {
          "ramSize": 100,
          "compaction": {
            "threshold": {
              "percentage": 50
            }
          }
        }
      }
    }
  }
}'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/wait_for_match.sh" \
  '{"name": "bucket_1", "check": [
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.percentage", "value": 50},
    {"key": ".autoCompactionSettings.parallelDBAndViewCompaction", "value": "true"}
  ]}' \
  '{"name": "bucket_2", "check": [
    {"key": ".autoCompactionSettings.parallelDBAndViewCompaction", "value": ""},
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.percentage", "value": 50}
  ]}' \
  '{"name": "bucket_3", "check": [
    {"key": ".autoCompactionSettings.parallelDBAndViewCompaction", "value": ""},
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.percentage", "value": 50}
  ]}'


  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  clean
}