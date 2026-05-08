#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

ZMK_WORKSPACE_DEFAULT=$(CDPATH= cd -- "$PROJECT_DIR/../../.." && pwd)
ZMK_WORKSPACE="${ZMK_WORKSPACE:-$ZMK_WORKSPACE_DEFAULT}"
SHIELD="${SHIELD:-tcherta}"
PRIVATE_DTSI="${PRIVATE_DTSI:-$PROJECT_DIR/boards/shields/${SHIELD}/DELETE_ME_orbita-password.dtsi}"

case "$SHIELD" in
  tcherta|plenka) ;;
  *)
    echo "Unsupported shield: $SHIELD (expected: tcherta or plenka)" >&2
    exit 1
    ;;
esac

cleanup() {
  rm -f "$PRIVATE_DTSI"
  unset PASS1 PASS2 PASS3
}
trap cleanup EXIT INT TERM

if [[ ! -d "$ZMK_WORKSPACE" ]]; then
  echo "Workspace not found: $ZMK_WORKSPACE" >&2
  exit 1
fi

read -r -p "Enter PASS1: " PASS1
printf '\n'
read -r -p "Enter PASS2: " PASS2
printf '\n'
read -r -p "Enter PASS3: " PASS3
printf '\n'

if [[ -z "$PASS1" || -z "$PASS2" || -z "$PASS3" ]]; then
  echo "All passwords must be non-empty." >&2
  exit 1
fi

char_to_binding() {
  local ch="$1"
  case "$ch" in
    [a-z]) printf '&macro_tap &kp %s' "${ch^^}" ;;
    [A-Z]) printf '&macro_tap &kp LS(%s)' "$ch" ;;
    [0-9]) printf '&macro_tap &kp N%s' "$ch" ;;
    '!') printf '&macro_tap &kp EXCL' ;;
    '@') printf '&macro_tap &kp AT_SIGN' ;;
    '#') printf '&macro_tap &kp HASH' ;;
    '$') printf '&macro_tap &kp DLLR' ;;
    '%') printf '&macro_tap &kp PRCNT' ;;
    '^') printf '&macro_tap &kp CARET' ;;
    '&') printf '&macro_tap &kp AMPS' ;;
    '*') printf '&macro_tap &kp STAR' ;;
    '(') printf '&macro_tap &kp LPAR' ;;
    ')') printf '&macro_tap &kp RPAR' ;;
    '-') printf '&macro_tap &kp MINUS' ;;
    '_') printf '&macro_tap &kp UNDER' ;;
    '=') printf '&macro_tap &kp EQUAL' ;;
    '+') printf '&macro_tap &kp PLUS' ;;
    '[') printf '&macro_tap &kp LBKT' ;;
    ']') printf '&macro_tap &kp RBKT' ;;
    '{') printf '&macro_tap &kp LBRC' ;;
    '}') printf '&macro_tap &kp RBRC' ;;
    ';') printf '&macro_tap &kp SEMI' ;;
    ':') printf '&macro_tap &kp COLON' ;;
    '\\') printf '&macro_tap &kp BSLH' ;;
    '|') printf '&macro_tap &kp PIPE' ;;
    ',') printf '&macro_tap &kp COMMA' ;;
    '.') printf '&macro_tap &kp DOT' ;;
    '/') printf '&macro_tap &kp FSLH' ;;
    '?') printf '&macro_tap &kp QMARK' ;;
    '~') printf '&macro_tap &kp TILDE' ;;
    '`') printf '&macro_tap &kp GRAVE' ;;
    '"') printf '&macro_tap &kp DQT' ;;
    "'") printf '&macro_tap &kp SQT' ;;
    '<') printf '&macro_tap &kp LT' ;;
    '>') printf '&macro_tap &kp GT' ;;
    ' ') printf '&macro_tap &kp SPACE' ;;
    *) return 1 ;;
  esac
}

emit_macro() {
  local macro_name="$1"
  local secret="$2"

  printf '        %s: %s {\n' "$macro_name" "$macro_name"
  printf '            compatible = "zmk,behavior-macro";\n'
  printf '            #binding-cells = <0>;\n'
  printf '            wait-ms = <20>;\n'
  printf '            tap-ms = <30>;\n'
  printf '            bindings\n'

  local first=1 i ch binding
  for ((i = 0; i < ${#secret}; i++)); do
    ch="${secret:i:1}"
    if ! binding="$(char_to_binding "$ch")"; then
      echo "Unsupported character in $macro_name: '$ch'" >&2
      exit 1
    fi

    # DTS bindings syntax uses '=' for the first entry, then ',' for subsequent entries.
    if (( first )); then
      printf '            = <%s>\n' "$binding"
      first=0
    else
      printf '            , <%s>\n' "$binding"
    fi
  done

  # Append Enter after each password sequence.
  printf '            , <&macro_tap &kp RET>\n'

  printf '            ;\n'
  printf '        };\n'
}

umask 077
{
  echo '/ {'
  echo '    macros {'
  emit_macro orbita_pass1 "$PASS1"
  emit_macro orbita_pass2 "$PASS2"
  emit_macro orbita_pass3 "$PASS3"
  echo '    };'
  echo '};'
  echo
  echo '#define PASS &none'
  echo '#define PASS1 &orbita_pass1'
  echo '#define PASS2 &orbita_pass2'
  echo '#define PASS3 &orbita_pass3'
} > "$PRIVATE_DTSI"

cd "$ZMK_WORKSPACE"
just build "$SHIELD"
