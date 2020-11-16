#!/bin/sh

# Check if config file exists.

# No config path was provided through env (required for now).
[ -n "$DIVAN_CONFIG" ] || {
  echo "missing config path" 1>&2
  exit 1
}
# The provided path doesn't point to a valid file.
[ -f "$DIVAN_CONFIG" ] || {
  printf "no such file : %s\n" "$DIVAN_CONFIG" 1>&2
  exit 1
}