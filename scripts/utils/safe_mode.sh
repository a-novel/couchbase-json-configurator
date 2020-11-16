#!/bin/sh

[ -z "$SAFE_MODE" ] || exit 0

# Safe mode prevents accidental data loss, since some modifications require re-creating the entire bucket. Values are:
# - DEV environment : disabled by default, can be enabled with a SAFE_MODE env variable to 1.
# - Other environment : enabled by default, can be disabled with a SAFE_MODE env variable to 0.
safeMode=1
{ [ -z "$ENV" ] || [ "$ENV" = "development" ]; } && safeMode=0

echo "export SAFE_MODE='$safeMode'"
exit 0