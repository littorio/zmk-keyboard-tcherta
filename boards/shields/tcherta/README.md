# Tcherta Sealed Build

This shield supports two build flows:

- `just build tcherta`: regular development build.  
  This works fine for development needs and does not ask for passwords.
- `just seal tcherta`: prompts for `PASS1`, `PASS2`, `PASS3`, injects them into a temporary local DTSI file, builds firmware, then removes the temporary file.

## First Run

From the ZMK workspace root, run:

```bash
modules/zmk/zmk-keyboard-tcherta/scripts/bootstrap_seal_target.sh .
```

This bootstrap step:

- ensures the local password build script is executable,
- provides the `seal` target by ensuring `Justfile` imports `modules/zmk/zmk-keyboard-tcherta/just/seal.just`,
- ensures `.gitignore` contains:
  - `boards/shields/tcherta/DELETE_ME_tcherta-password.dtsi`

## Sealed Build

Run:

```bash
just seal tcherta
```

What happens:

1. You are prompted for `PASS1`, `PASS2`, `PASS3`.
2. A temporary file is created at:
   - `boards/shields/tcherta/DELETE_ME_tcherta-password.dtsi`
3. Build runs via `just build tcherta`.
4. Temporary file is deleted on exit (`trap`), including interrupt/error paths.

## Notes

- The passwords are still embedded in the resulting firmware image.
- For normal keymap/layout development, use `just build tcherta`.
