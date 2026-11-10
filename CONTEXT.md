# Project Context: zmk-keyboard-tcherta

Purpose: keyboard module containing physical shield definitions and local build
helpers. The active branch, `tcherta_shield_0`, supports `tcherta`.

## Layout

- `boards/shields/tcherta/`: tcherta shield configs/overlays/docs
- `scripts/`: helper scripts for bootstrapping and sealed builds
- `build.yaml`, `west.yml`, `zephyr/module.yml`: ZMK/Zephyr module integration files

Plenka sources are retained on the `plenka_1` branch. They are not present on
the active branch and must not be listed as active build targets until restored
or merged deliberately.

## Shared Layout Relationship

This module now treats shield keymaps as thin wrappers and pulls common layout
logic from the local shared module:

- `modules/zmk/zmk-orbita-layout/include/orbita_layout.keymap.inc`

`tcherta.keymap` includes:
- optional local password DTSI (`DELETE_ME_orbita-password.dtsi`)
- shared orbita layout include

## Build Flows

- Regular dev builds:
  - `just build tcherta`
  - no password prompts

- Sealed build:
  - `just seal tcherta`
  - prompts for `PASS1`, `PASS2`, `PASS3`
  - generates temporary DTSI under matching shield directory:
    - `boards/shields/tcherta/DELETE_ME_orbita-password.dtsi`
  - runs `just build <shield>`
  - removes temporary DTSI on exit via trap cleanup

## Seal Implementation Notes

- Bootstrap script:
  - `scripts/bootstrap_seal_target.sh`
  - ensures workspace `Justfile` imports `modules/zmk/zmk-orbita-layout/just/seal.just`
  - ensures temporary DTSI paths are ignored in `.gitignore`

- Password macro script (shared module):
  - `modules/zmk/zmk-orbita-layout/scripts/orbita_build_with_passwords.sh`
  - maps password characters to ZMK macro key bindings
  - emits `PASS1`, `PASS2`, `PASS3` bindings into temporary DTSI
  - each emitted password macro appends `&kp RET` at end

## Security/Behavior Caveats

- Passwords are embedded in resulting firmware image.
- Sealed flow avoids keeping plaintext DTSI in repo by deleting generated file after build.
- Input prompts are visible by design in this project’s workflow.
