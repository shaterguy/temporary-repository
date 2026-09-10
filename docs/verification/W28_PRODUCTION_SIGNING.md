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

The production workflow does not create a new signing key. This is deliberate: generating a replacement key inside every CI run would destroy update continuity. If the protected backend is missing, the workflow must stop before downloading the expensive export toolchain and before creating any APK.

## Remote production workflow

`.github/workflows/w28-production-signing.yml` is `workflow_dispatch` only and has `contents: read` permission. Once the protected signer exists, it performs these tiers:

1. STATIC_PREFLIGHT: validate the W28 source contract, exact Godot/toolchain hashes, product identity and no-source-secret rule.
2. SECRET_GATE: require all four durable signer values and validate the expected certificate fingerprint shape without printing secret values.
3. ARTIFACT_BUILD: install the pinned Godot 4.7.2 editor/export templates and pinned Android build-tools contract, materialize the keystore only under `/tmp`, and perform `--export-release` using Godot's release-keystore environment overrides.
4. ARTIFACT_VERIFY: verify package/version with `aapt`, APK signature and public certificate fingerprint with `apksigner`, 16 KB ZIP/native ELF compatibility with `zipalign`/`readelf`, then record APK SHA-256 and size.
5. PUBLISH_DELIVER: upload only the APK and non-secret metadata. Artifact identity includes both GitHub run ID and run attempt. The keystore is deleted in an `always()` cleanup step and is never uploaded.

## Runtime asset/license gate

`tests/ci/check_w28_release_contract.py` walks all runtime-manifest groups declared by `content_manifest.json`, requires each group to declare an existing project license record, rejects `placeholder=true` and nonzero `placeholder_count`, and preserves the top-level rule that every runtime asset needs license tracking. This is a release-contract audit, not a substitute for pending human art/listening review.

## Current blocked dependency

`SIGNING_SECRET_BACKEND_STATUS=BLOCKED_UNAVAILABLE_IN_CONNECTED_GITHUB_TOOL`

At this checkpoint the connected GitHub interface does not expose repository Actions Secrets create/update operations, and no LANTERNFALL production keystore exists in the allowed project sources. Therefore this tranche must not dispatch the production signing workflow and must not produce or hand over a debug/ad-hoc APK. The unrelated `musevault-signing-pass.txt` material is explicitly out of scope and must never be reused for LANTERNFALL.

When a protected remote signing backend becomes available, the same workflow is ready to produce the first production-signed APK without changing gameplay source. The first successful signer fingerprint becomes the production update lineage and all later production APKs must match `LANTERNFALL_PROD_CERT_SHA256`.
