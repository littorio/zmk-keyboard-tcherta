#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
WORKSPACE_DEFAULT=$(CDPATH= cd -- "$PROJECT_DIR/../../.." && pwd)

WORKSPACE_DIR="${1:-${ZMK_WORKSPACE:-$WORKSPACE_DEFAULT}}"
JUSTFILE="$WORKSPACE_DIR/Justfile"
HELPER_SCRIPT="$PROJECT_DIR/scripts/tcherta_build_with_passwords.sh"
SEAL_MODULE="$PROJECT_DIR/just/seal.just"
PROJECT_GITIGNORE="$PROJECT_DIR/.gitignore"
IMPORT_LINE="import 'modules/zmk/zmk-keyboard-tcherta/just/seal.just'"
TEMP_DTSI_RELS=(
  "boards/shields/tcherta/DELETE_ME_orbita-password.dtsi"
  "boards/shields/plenka/DELETE_ME_orbita-password.dtsi"
)

if [[ ! -f "$JUSTFILE" ]]; then
  echo "Justfile not found: $JUSTFILE" >&2
  exit 1
fi

if [[ ! -f "$HELPER_SCRIPT" ]]; then
  echo "Helper script not found: $HELPER_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$SEAL_MODULE" ]]; then
  echo "Seal module not found: $SEAL_MODULE" >&2
  exit 1
fi

if [[ ! -x "$HELPER_SCRIPT" ]]; then
  if ! chmod +x "$HELPER_SCRIPT" 2>/dev/null; then
    echo "Cannot make helper script executable: $HELPER_SCRIPT" >&2
    echo "Run once: chmod +x $HELPER_SCRIPT" >&2
    exit 1
  fi
fi

# Cleanup older marker-based embedded block, if present.
if rg -q '^# >>> tcherta-seal begin$' "$JUSTFILE"; then
  justfile_tmp="$(mktemp)"
  trap 'rm -f "$justfile_tmp"' EXIT INT TERM
  awk '
    /^# >>> tcherta-seal begin$/ {drop=1; next}
    /^# <<< tcherta-seal end$/   {drop=0; next}
    !drop {print}
  ' "$JUSTFILE" > "$justfile_tmp"
  mv "$justfile_tmp" "$JUSTFILE"
  trap - EXIT INT TERM
  echo "Removed legacy embedded seal block from $JUSTFILE"
fi

if rg -q "^${IMPORT_LINE}\$" "$JUSTFILE"; then
  echo "Seal import already exists in $JUSTFILE"
elif rg -q '^seal expr:' "$JUSTFILE"; then
  echo "Found existing inline 'seal expr:' recipe in $JUSTFILE." >&2
  echo "Please remove it, then rerun bootstrap to install import-based seal module." >&2
  exit 1
else
  justfile_tmp="$(mktemp)"
  trap 'rm -f "$justfile_tmp"' EXIT INT TERM
  awk -v import_line="$IMPORT_LINE" '
    !inserted && /^draw := absolute_path\('\''draw'\''\)$/ {
      print
      print ""
      print import_line
      inserted=1
      next
    }
    { print }
    END {
      if (!inserted) {
        print ""
        print import_line
      }
    }
  ' "$JUSTFILE" > "$justfile_tmp"
  mv "$justfile_tmp" "$JUSTFILE"
  trap - EXIT INT TERM
  echo "Added seal import to $JUSTFILE"
fi

if [[ ! -e "$PROJECT_GITIGNORE" ]]; then
  if ! touch "$PROJECT_GITIGNORE" 2>/dev/null; then
    echo "Warning: cannot create $PROJECT_GITIGNORE; skipped ignore rule update." >&2
    echo "Bootstrap complete."
    exit 0
  fi
fi

if [[ ! -w "$PROJECT_GITIGNORE" ]]; then
  echo "Warning: $PROJECT_GITIGNORE is not writable; skipped ignore rule update." >&2
  echo "Bootstrap complete."
  exit 0
fi

for rel in "${TEMP_DTSI_RELS[@]}"; do
  if ! rg -q "^${rel}\$" "$PROJECT_GITIGNORE"; then
    echo "$rel" >> "$PROJECT_GITIGNORE"
    echo "Added ignore rule to $PROJECT_GITIGNORE: $rel"
  fi
done

echo "Bootstrap complete."
