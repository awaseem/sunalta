#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -module-cache-path "$check_dir/modules" -parse-as-library \
  clock-app/AlarmTimeInput.swift Tests/AlarmTimeInputChecks.swift \
  -o "$check_dir/time-input-checks"
"$check_dir/time-input-checks"
