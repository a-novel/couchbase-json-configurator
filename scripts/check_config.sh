#!/bin/sh

# This script is aimed to perform the maximum amount of validation before running any setup script. This avoid running
# useless operation, and helps user to quickly identify issues with its configuration.

# Check credentials.

credentials_output="$(sh "$DIVAN_SCRIPTS/check_utils/check_config_credentials.sh")" || {
  printf "%s" "$credentials_output" 1>&2
  exit 1
}

resources_output="$(sh "$DIVAN_SCRIPTS/check_utils/check_config_resources.sh")" || {
  printf "%s" "$resources_output" 1>&2
  exit 1
}

# Export data in ENV.
echo "export $credentials_output $resources_output"
exit 0