# Project Context: zmk-keyboard-tcherta

Purpose: custom ZMK module containing keyboard shield definitions and local build helpers, with an optional sealed-password build flow for the `tcherta` shield.

## Layout

- `boards/shields/tcherta/`: primary shield (keymap, overlays, configs, docs)
- `boards/shields/plenka/`: additional shield in same module
- `scripts/`: helper scripts for bootstrapping and sealed builds
- `just/seal.just`: imported just recipe providing `just seal tcherta`
- `build.yaml`, `west.yml`, `zephyr/module.yml`: ZMK/Zephyr module integration files

## Build Flows

- Regular dev build:
  - `just build tcherta`
  - no password prompts

- Sealed build:
  - `just seal tcherta`
  - prompts for `PASS1`, `PASS2`, `PASS3`
  - generates temporary DTSI:
    - `boards/shields/tcherta/DELETE_ME_tcherta-password.dtsi`
  - runs `just build tcherta`
  - removes temporary DTSI on exit via trap cleanup

## Seal Implementation Notes

- Bootstrap script:
  - `scripts/bootstrap_seal_target.sh`
  - ensures workspace `Justfile` imports `modules/zmk/zmk-keyboard-tcherta/just/seal.just`
  - ensures temporary DTSI path is ignored in `.gitignore`

- Password macro script:
  - `scripts/tcherta_build_with_passwords.sh`
  - maps password characters to ZMK macro key bindings
  - emits `PASS1`, `PASS2`, `PASS3` bindings into temporary DTSI
  - each emitted password macro appends `&kp RET` at end

## Keymap Integration

- `boards/shields/tcherta/tcherta.keymap` conditionally includes temporary DTSI with:
  - `#if __has_include("DELETE_ME_tcherta-password.dtsi")`
- Default fallbacks define `PASS`, `PASS1`, `PASS2`, `PASS3` as `&none` when no sealed DTSI is present.

## Security/Behavior Caveats

- Passwords are embedded in resulting firmware image.
- Sealed flow avoids keeping plaintext DTSI in repo by deleting generated file after build.
- Input prompts are visible by design in this project’s workflow.
