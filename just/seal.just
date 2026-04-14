# build tcherta with prompted passwords from local helper script
seal expr:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ "{{ expr }}" != "tcherta" ]]; then
        echo "seal currently supports only 'tcherta'." >&2
        exit 1
    fi

    script="${SEAL_SCRIPT:-{{ justfile_directory() }}/modules/zmk/zmk-keyboard-tcherta/scripts/tcherta_build_with_passwords.sh}"

    if [[ ! -x "$script" ]]; then
        echo "Missing executable script: $script" >&2
        echo "Set SEAL_SCRIPT to override script location." >&2
        exit 1
    fi

    ZMK_WORKSPACE="{{ justfile_directory() }}" \
    PRIVATE_DTSI="{{ justfile_directory() }}/modules/zmk/zmk-keyboard-tcherta/boards/shields/tcherta/DELETE_ME_tcherta-password.dtsi" \
    "$script"
