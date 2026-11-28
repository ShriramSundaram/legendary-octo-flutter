#!/usr/bin/env bash
set -euo pipefail

log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT

for attempt in 1 2 3; do
  if flutter build apk --debug --split-per-abi --no-pub 2>&1 | tee "$log_file"; then
    exit 0
  else
    statuses=("${PIPESTATUS[@]}")
  fi
  # A broken output pipe must not be reported as a successful build.
  if (( statuses[1] != 0 )); then
    exit "${statuses[1]}"
  fi
  if (( attempt == 3 )) || ! grep -Eq 'Received status code (429|502|503|504) from server' "$log_file"; then
    exit "${statuses[0]}"
  fi
  delay=$((attempt * 30))
  echo "Temporary dependency download failure; retrying in ${delay}s (attempt $((attempt + 1))/3)."
  sleep "$delay"
done
