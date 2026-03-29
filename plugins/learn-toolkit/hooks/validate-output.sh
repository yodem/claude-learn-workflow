#!/usr/bin/env bash
# validate-output.sh
# PostToolUse hook: validates that files written by learn-toolkit have correct structure.
# Reads tool use JSON from stdin. Exit 0 to allow, exit 2 to block with message.

set -euo pipefail

# Read stdin JSON
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || true)

# Only validate files in /tmp/learn-* directories
if [[ "$FILE_PATH" != /tmp/learn-* ]]; then
  exit 0
fi

# Validate README.md has required sections
if [[ "$FILE_PATH" == */README.md ]]; then
  if ! grep -q "^#" "$FILE_PATH" 2>/dev/null; then
    echo "ERROR: $FILE_PATH is missing a top-level heading" >&2
    exit 2
  fi
fi

# Validate research-summary.md has minimum length (~500 words = ~3000 chars)
if [[ "$FILE_PATH" == */research-summary.md ]]; then
  CHAR_COUNT=$(wc -c < "$FILE_PATH" 2>/dev/null || echo 0)
  if [[ "$CHAR_COUNT" -lt 500 ]]; then
    echo "WARNING: $FILE_PATH looks too short (${CHAR_COUNT} chars) — expected ~3000 chars for a 500-word summary" >&2
    # Don't block (exit 2) — just warn and allow
  fi
fi

# Validate workflow state JSON is well-formed
if [[ "$FILE_PATH" == /tmp/learn-workflow-state.json ]]; then
  if ! jq empty "$FILE_PATH" 2>/dev/null; then
    echo "ERROR: $FILE_PATH is not valid JSON" >&2
    exit 2
  fi
  # Check required keys
  for KEY in topic notebooks total_sources local_path; do
    if ! jq -e "has(\"$KEY\")" "$FILE_PATH" >/dev/null 2>&1; then
      echo "ERROR: $FILE_PATH is missing required key: $KEY" >&2
      exit 2
    fi
  done
fi

exit 0
