#!/bin/sh

old_ds="$DIVAN_SCRIPTS"
cdir="$(pwd)"
export DIVAN_SCRIPTS="$cdir"

go test -v ./tests/check_tests -count=1 -timeout 99999s
go test -v ./tests/update_tests -count=1 -timeout 99999s

export DIVAN_SCRIPTS="$old_ds"