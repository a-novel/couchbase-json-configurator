#!/usr/bin/env bats

teardown() {
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
  
  load_data="$(sh "$DIVAN_SCRIPTS/check_config.sh")" || {
    printf "%s" "$load_data" 1>&2
    exit 1
  }
  
  eval "$load_data"
  
  output="$(sh "$DIVAN_SCRIPTS/create_cluster.sh" 1>/dev/null)" || {
    printf "# %s\n" "$output" >&3
    exit 1
  }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to create cluster with correct compaction value")" {
  run "$BATS_TEST_DIRNAME/utils/cluster_compaction.sh" '{
    "threshold": {
      "percentage": 80,
      "size": 1024
    },
    "viewThreshold": {
      "percentage": 60,
      "size": 512
    },
    "from": {
      "hour": 2,
      "minute": 30
    },
    "to": {
      "hour": 6,
      "minute": 45
    },
    "abortOutside": true,
    "parallelCompaction": true
  }' \
  "[
    {\"key\": \".autoCompactionSettings.parallelDBAndViewCompaction\", \"value\": \"true\"},
    {\"key\": \".autoCompactionSettings.allowedTimePeriod.abortOutside\", \"value\": \"true\"},
    {\"key\": \".autoCompactionSettings.allowedTimePeriod.fromHour\", \"value\": 2},
    {\"key\": \".autoCompactionSettings.allowedTimePeriod.fromMinute\", \"value\": 30},
    {\"key\": \".autoCompactionSettings.allowedTimePeriod.toHour\", \"value\": 6},
    {\"key\": \".autoCompactionSettings.allowedTimePeriod.toMinute\", \"value\": 45},
    {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.percentage\", \"value\": 80},
    {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.size\", \"value\": $((1024 * 1048576))},
    {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.percentage\", \"value\": 60},
    {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.size\", \"value\": $((512 * 1048576))}
  ]"

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to remove compaction on cluster when unset")" {
  run "$BATS_TEST_DIRNAME/utils/cluster_compaction.sh" '' \
  '[
    {"key": ".autoCompactionSettings.parallelDBAndViewCompaction", "value": ""},
    {"key": ".autoCompactionSettings.allowedTimePeriod.abortOutside", "value": ""},
    {"key": ".autoCompactionSettings.allowedTimePeriod.fromHour", "value": ""},
    {"key": ".autoCompactionSettings.allowedTimePeriod.fromMinute", "value": ""},
    {"key": ".autoCompactionSettings.allowedTimePeriod.toHour", "value": ""},
    {"key": ".autoCompactionSettings.allowedTimePeriod.toMinute", "value": ""},
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.percentage", "value": ""},
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.size", "value": ""},
    {"key": ".autoCompactionSettings.viewFragmentationThreshold.percentage", "value": ""},
    {"key": ".autoCompactionSettings.viewFragmentationThreshold.size", "value": ""}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to update global compaction threshold normally")" {
  run "$BATS_TEST_DIRNAME/utils/cluster_compaction.sh" '{
    "threshold": {
      "percentage": 80
    }
  }' \
  '[
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.percentage", "value": 80},
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.size", "value": ""},
    {"key": ".autoCompactionSettings.viewFragmentationThreshold.percentage", "value": ""},
    {"key": ".autoCompactionSettings.viewFragmentationThreshold.size", "value": ""}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }
  
  run "$BATS_TEST_DIRNAME/utils/cluster_compaction.sh" '{
    "threshold": {
      "size": 1024
    }
  }' \
  "[
    {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.percentage\", \"value\": \"\"},
    {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.size\", \"value\": $((1024 * 1048576))},
    {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.percentage\", \"value\": \"\"},
    {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.size\", \"value\": \"\"}
  ]"

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/cluster_compaction.sh" '{
    "viewThreshold": {
      "percentage": 60
    }
  }' \
  '[
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.percentage", "value": ""},
    {"key": ".autoCompactionSettings.databaseFragmentationThreshold.size", "value": ""},
    {"key": ".autoCompactionSettings.viewFragmentationThreshold.percentage", "value": 60},
    {"key": ".autoCompactionSettings.viewFragmentationThreshold.size", "value": ""}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }

  run "$BATS_TEST_DIRNAME/utils/cluster_compaction.sh" '{
    "viewThreshold": {
      "size": 512
    }
  }' \
  "[
    {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.percentage\", \"value\": \"\"},
    {\"key\": \".autoCompactionSettings.databaseFragmentationThreshold.size\", \"value\": \"\"},
    {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.percentage\", \"value\": \"\"},
    {\"key\": \".autoCompactionSettings.viewFragmentationThreshold.size\", \"value\": $((512 * 1048576))}
  ]"

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }
}

@test "$(printf "\033[0;33mexpect run\033[0;37m to update global compaction timeframe normally")" {
  run "$BATS_TEST_DIRNAME/utils/cluster_compaction.sh" '{
    "threshold": {
      "percentage": 80
    },
    "from": {
      "hour": 2,
      "minute": 30
    },
    "to": {
      "hour": 6,
      "minute": 45
    }
  }' \
  '[
    {"key": ".autoCompactionSettings.allowedTimePeriod.abortOutside", "value": ""},
    {"key": ".autoCompactionSettings.allowedTimePeriod.fromHour", "value": 2},
    {"key": ".autoCompactionSettings.allowedTimePeriod.fromMinute", "value": 30},
    {"key": ".autoCompactionSettings.allowedTimePeriod.toHour", "value": 6},
    {"key": ".autoCompactionSettings.allowedTimePeriod.toMinute", "value": 45}
  ]'

  [ "$status" -eq 0 ] || { printf "# %s\n" "$output" >&3; exit 1; }
}
