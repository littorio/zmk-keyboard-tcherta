# build shield with prompted passwords from local helper script
seal expr:
    #!/usr/bin/env bash
    set -euo pipefail

    shield="{{ expr }}"
    case "$shield" in
        tcherta|plenka) ;;
        *)
            echo "seal supports only 'tcherta' or 'plenka'." >&2
            exit 1
            ;;
    esac

    script="${SEAL_SCRIPT:-{{ justfile_directory() }}/modules/zmk/zmk-keyboard-tcherta/scripts/tcherta_build_with_passwords.sh}"

    if [[ ! -x "$script" ]]; then
        echo "Missing executable script: $script" >&2
        echo "Set SEAL_SCRIPT to override script location." >&2
        exit 1
    fi

    ZMK_WORKSPACE="{{ justfile_directory() }}" \
    SHIELD="$shield" \
    PRIVATE_DTSI="{{ justfile_directory() }}/modules/zmk/zmk-keyboard-tcherta/boards/shields/${shield}/DELETE_ME_orbita-password.dtsi" \
    "$script"
