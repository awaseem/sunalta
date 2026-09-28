# Alarm model checks

Run `sh Tests/run-model-checks.sh` on macOS with Xcode selected. This compiles the actual model files and checks an on-disk SwiftData store across container recreation, shared relationships, deletion rules, invalid settings, and Foqos-compatible scan matching. The iOS app build also compiles the AlarmKit schedule adapter.

Run `sh Tests/run-time-input-checks.sh` to check every four-digit keypad combination against valid 24-hour times, plus completion and backspace behavior.
