#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -module-cache-path "$check_dir/modules" -parse-as-library \
  clock-app/ClockWeekday.swift clock-app/Models/AlarmRecord.swift \
  clock-app/Models/AlarmStopTarget.swift Tests/AlarmModelChecks.swift \
  -o "$check_dir/model-checks"
"$check_dir/model-checks"
