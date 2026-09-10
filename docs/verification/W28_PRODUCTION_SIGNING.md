# W28 production signing and first-install lineage

Task: `SR-20260909-150106-PPO12Y`
Baseline branch: `v1.0.0-dev1`
Baseline commit: `775e7034aef9c5c0f018a65750504e15fe3d21fe`
Test contract: `w28-production-signing-contract-v1`

## Contract preflight

- `TEST_CONTRACT_PREFLIGHT=VALID`
- `ACTION_PREFLIGHT=VALID`
- `SECURITY_CLASS=HIGH_RISK_OPERATION`
- `SECURITY_DELTA=MATERIAL`
- Existing gameplay, W27 soak, save schema, world schema and package identities are unchanged by this W28 preparation tranche.
- No debug keystore, generated-per-run key, unrelated project key, private key, password or base64 keystore is committed.

## Production identity

- Product: `LANTERNFALL: 잔광의 항로`
- Version name: `1.0.0-dev1`
- Version code: `1`
- Production application ID: `com.shaterguy.lanternfall`
- Development application ID remains separate: `com.shaterguy.lanternfall.dev`
- Primary production ABI: `arm64-v8a`
- Production export preset: `Android Production`
- User-facing artifact name: `LANTERNFALL-1.0.0-dev1-production.apk`

## Durable signing boundary

The first user-installable production APK must be signed by one durable non-debug key and every later production in-place update must continue that certificate lineage. The source tree contains only the signing contract. Protected material is injected only at GitHub Actions runtime through repository-level protected secrets or an equivalent remote secret backend.

Required protected values:

- `LANTERNFALL_PROD_KEYSTORE_B64`: base64 encoding of the durable production keystore bytes.
- `LANTERNFALL_PROD_KEY_ALIAS`: key alias stored in that keystore.
- `LANTERNFALL_PROD_KEY_PASSWORD`: keystore/key password. Godot requires the release keystore and key password contract to be compatible.
- `LANTERNFALL_PROD_CERT_SHA256`: normalized expected SHA-256 fingerprint for the signing certificate; the workflow compares the APK signer against it and fails on key replacement.

The production workflow does not create a new signing key. This is deliberate: generating a replacement key inside every CI run would destroy update continuity. If the protected backend is missing, no signing branch is created or moved and no APK is produced.

## Remote production workflow

`.github/workflows/w28-production-signing.yml` is triggered only by a push to the dedicated `sign/w28-production` branch and has `contents: read` permission. The dedicated branch is intentionally absent while the protected signer is unavailable. After the four protected signer values exist, the branch must be created or fast-forwarded to the exact already-verified `v1.0.0-dev1` HEAD. The workflow then performs these tiers:

1. CANDIDATE_SYNC: fetch `v1.0.0-dev1` and require the signing-branch HEAD to equal the current dev HEAD before any signer secret is used. A stale or independently modified signing branch fails closed.
2. STATIC_PREFLIGHT: validate the W28 source contract, exact Godot/toolchain hashes, product identity and no-source-secret rule.
3. SECRET_GATE: require all four durable signer values and validate the expected certificate fingerprint shape without printing secret values.
4. ARTIFACT_BUILD: install the pinned Godot 4.7.2 editor/export templates and pinned Android build-tools contract, materialize the keystore only under `/tmp`, and perform `--export-release` using Godot's release-keystore environment overrides.
5. ARTIFACT_VERIFY: verify package/version with `aapt`, APK signature and public certificate fingerprint with `apksigner`, 16 KB ZIP/native ELF compatibility with `zipalign`/`readelf`, then record APK SHA-256 and size.
6. PUBLISH_DELIVER: upload only the APK and non-secret metadata. Artifact identity includes both GitHub run ID and run attempt. The keystore is deleted in an `always()` cleanup step and is never uploaded.

This dedicated push trigger is used because a `workflow_dispatch` workflow must exist on the repository default branch before GitHub accepts manual dispatch events. W28 does not modify `main`; therefore relying on a dev-only `workflow_dispatch` file would make the signing path non-executable.

## Runtime asset/license gate

`tests/ci/check_w28_release_contract.py` walks all runtime-manifest groups declared by `content_manifest.json`, requires each group to declare an existing project license record, rejects `placeholder=true` and nonzero `placeholder_count`, and preserves the top-level rule that every runtime asset needs license tracking. This is a release-contract audit, not a substitute for pending human art/listening review.

## Current blocked dependency

`SIGNING_SECRET_BACKEND_STATUS=BLOCKED_UNAVAILABLE_IN_CONNECTED_GITHUB_TOOL`

At this checkpoint the connected GitHub interface does not expose repository Actions Secrets create/update operations, and no LANTERNFALL production keystore exists in the allowed project sources. Therefore this tranche must not create/move `sign/w28-production` merely to probe secret presence and must not produce or hand over a debug/ad-hoc APK. The unrelated `musevault-signing-pass.txt` material is explicitly out of scope and must never be reused for LANTERNFALL.

When a protected remote signing backend becomes available, provision the four protected values first, then create or fast-forward `sign/w28-production` to the exact verified `v1.0.0-dev1` HEAD. The first successful signer fingerprint becomes the production update lineage and all later production APKs must match `LANTERNFALL_PROD_CERT_SHA256`.
