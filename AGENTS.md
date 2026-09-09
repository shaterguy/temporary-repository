# Repository working contract

This repository is the authoritative source for LANTERNFALL implementation and verification.

## Scope and branch discipline

- Keep `main` as the stable repository baseline. Development work belongs on versioned dev/RC branches such as `v1.0.0-dev1` until independently verified and promoted.
- Do not force-push, rewrite history, or fold unrelated cleanup into a feature change.
- Every meaningful code/config change must map to the product acceptance criteria recorded in `docs/verification/REQUIREMENT_TRACE.md`.
- A foundation shell, passing CI, or a vertical slice is not the completed game and must never be represented as the premium-quality target being achieved.

## Toolchain and validation

- Use the exact engine and digest recorded in `toolchain.lock`.
- Run cheap/static checks before headless fast tests; add Android export/runtime tiers only when their prerequisites are satisfied.
- Remote GitHub state and remote CI are verification authority. Do not substitute local-only builds or untracked working copies for release evidence.

## Signing and secrets

- The first user-installable APK must use a durable non-debug signing lineage.
- DEV and PROD package/signing lineages are separate and must remain update-compatible within each lineage.
- Never commit keystores, private keys, signing passwords, tokens, cookies, or unrelated applications' signing material.
- Do not fall back to a debug key or generate a replacement key per build when protected signing material is unavailable.

## Runtime product boundary

The current product baseline is offline single-player. New runtime network access, accounts, broad storage access, advertising, payments, analytics, or additional Android permissions require an explicit product/security review before implementation.
