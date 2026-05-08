# Project Context: zmk-keyboard-tcherta

Purpose: keyboard module containing shield definitions and local build helpers for
`tcherta` and `plenka`, with optional sealed-password build flow.

## Layout

- `boards/shields/tcherta/`: tcherta shield configs/overlays/docs
- `boards/shields/plenka/`: plenka shield configs/overlays/docs
- `scripts/`: helper scripts for bootstrapping and sealed builds
- `just/seal.just`: imported just recipe providing `just seal <shield>`
- `build.yaml`, `west.yml`, `zephyr/module.yml`: ZMK/Zephyr module integration files

## Shared Layout Relationship

This module now treats shield keymaps as thin wrappers and pulls common layout
logic from the local shared module:

- `modules/zmk/orbita-layout/include/orbita_layout.keymap.inc`

`tcherta.keymap` includes:
- optional local password DTSI (`DELETE_ME_orbita-password.dtsi`)
- shared orbita layout include

## Build Flows

- Regular dev builds:
  - `just build tcherta`
  - `just build plenka`
  - no password prompts

- Sealed build:
  - `just seal tcherta` or `just seal plenka`
  - prompts for `PASS1`, `PASS2`, `PASS3`
  - generates temporary DTSI under matching shield directory:
    - `boards/shields/tcherta/DELETE_ME_orbita-password.dtsi`
    - `boards/shields/plenka/DELETE_ME_orbita-password.dtsi`
  - runs `just build <shield>`
  - removes temporary DTSI on exit via trap cleanup

## Seal Implementation Notes

- Bootstrap script:
  - `scripts/bootstrap_seal_target.sh`
  - ensures workspace `Justfile` imports `modules/zmk/zmk-keyboard-tcherta/just/seal.just`
  - ensures temporary DTSI paths are ignored in `.gitignore`

- Password macro script:
  - `scripts/tcherta_build_with_passwords.sh`
  - shield-aware (`tcherta` / `plenka`)
  - maps password characters to ZMK macro key bindings
  - emits `PASS1`, `PASS2`, `PASS3` bindings into temporary DTSI
  - each emitted password macro appends `&kp RET` at end

## Security/Behavior Caveats

- Passwords are embedded in resulting firmware image.
- Sealed flow avoids keeping plaintext DTSI in repo by deleting generated file after build.
- Input prompts are visible by design in this project’s workflow.

## TODO

- Create a dedicated GitHub repository for `orbita-layout` and place it under remote version control.
- Ensure this module depends on the remote-tracked `orbita-layout` source (not local-only files).
