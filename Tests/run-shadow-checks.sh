#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -module-cache-path "$check_dir/modules" -parse-as-library \
  clock-app/Components/Clock/ClockShadowProjection.swift Tests/ClockShadowProjectionChecks.swift \
  -o "$check_dir/shadow-checks"
"$check_dir/shadow-checks"
