# W28 production signing and first-install lineage

Task: `SR-20260909-150106-PPO12Y`
Continuation: `SR-20260910-121926-5B5U4L`
Baseline branch: `v1.0.0-dev1`
Original W28 baseline commit: `775e7034aef9c5c0f018a65750504e15fe3d21fe`
Current rebuild baseline: `157844b996767abbe11ca05a1226910dd68fd2d5`
Test contract: `w28-production-signing-contract-v1`

## Contract preflight

- `TEST_CONTRACT_PREFLIGHT=VALID`
- `ACTION_PREFLIGHT=VALID`
- `SECURITY_CLASS=HIGH_RISK_OPERATION`
- `SECURITY_DELTA=MATERIAL`
- Existing gameplay, save schema, world schema and package identities remain unchanged by the production-signing mechanism.
- The current rebuild is required because R04 found and the W25 repair fixed a product-level Android touch-entry defect after the first W28 APK was produced.
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

The first user-installable production APK and every rebuilt candidate in the same production lineage must be signed by the same durable non-debug key. Every later production in-place update must continue that certificate lineage. Protected material is injected only at GitHub Actions runtime through repository-level protected secrets or an equivalent remote secret backend.

Required protected values:

- `LANTERNFALL_PROD_KEYSTORE_B64`: base64 encoding of the durable production keystore bytes.
- `LANTERNFALL_PROD_KEY_ALIAS`: key alias stored in that keystore.
- `LANTERNFALL_PROD_KEY_PASSWORD`: keystore/key password.
- `LANTERNFALL_PROD_CERT_SHA256`: expected SHA-256 fingerprint for the production signing certificate.

The production workflow never creates a replacement signing key. It materializes the protected keystore only under `/tmp`, verifies the signer fingerprint, uploads only APK plus non-secret metadata, and removes the keystore in an `always()` cleanup step.

## Proven signer state

The earlier source-state document incorrectly remained at `SIGNING_SECRET_BACKEND_STATUS=BLOCKED_UNAVAILABLE_IN_CONNECTED_GITHUB_TOOL` after the signer was actually provisioned through the repository's protected Actions environment. That status is now stale and retired.

Authoritative remote evidence is W28 production-signing run `34445663426` on source SHA `eb4b542275f13929334d72cc4e3eba492bb8ef9c`, which completed successfully and produced artifact ID `10139569453`. The resulting APK was `LANTERNFALL-1.0.0-dev1-production.apk`, SHA-256 `5ff25fec7915ce9c05c7d3cadccde4b00c9821dc0b5069228b8b239dc6a1bba5`, signed with certificate SHA-256 `114bb489ccfdcd7137b70aeb3230bbdd29af08f0e3155ee817419e1afd8269ef`, and passed the W28 package/version/signature/16 KB checks.

That old APK is no longer the final candidate because R04 API36 runtime verification exposed the missing touch-only path from first launch into gameplay. The product repair is now on `v1.0.0-dev1`; therefore a new APK must be built from the exact current verified dev HEAD using the same protected signer and certificate lineage. The old APK remains historical evidence only.

## Remote production workflow

`.github/workflows/w28-production-signing.yml` is triggered only by a push to `sign/w28-production` and has `contents: read` permission. Before any signer secret is used it fetches `v1.0.0-dev1` and requires the signing-branch HEAD to equal the current dev HEAD exactly. A stale or independently modified signing branch fails closed.

The workflow tiers are:

1. CANDIDATE_SYNC: require exact SHA equality with current `v1.0.0-dev1`.
2. STATIC_PREFLIGHT: validate W28 source contract, pinned Godot/toolchain hashes, production identity and no-source-secret rule.
3. SECRET_GATE: require all four durable signer values and validate the expected certificate fingerprint shape without printing secrets.
4. ARTIFACT_BUILD: install the pinned Godot 4.7.2 editor/export templates and Android Build Tools `36.1.0`, materialize the protected keystore only under `/tmp`, and perform `--export-release` using the release-keystore environment overrides.
5. ARTIFACT_VERIFY: verify package/version with `aapt`, APK signature and certificate fingerprint with `apksigner`, 16 KB ZIP/native ELF compatibility with `zipalign`/`readelf`, and record APK SHA-256 and size.
6. PUBLISH_DELIVER: upload only the APK and non-secret metadata with run-ID/run-attempt-specific artifact identity.

## Runtime asset/license gate

`tests/ci/check_w28_release_contract.py` walks all runtime-manifest groups declared by `content_manifest.json`, requires each group to declare an existing project license record, rejects placeholders, and preserves the rule that every runtime asset needs license tracking. This release-contract audit remains valid and does not substitute for device-specific post-delivery observations.

## Current rebuild gate

`v1.0.0-dev1` must first have the affected source/test regressions green. W25 has already passed the new touch-first `SLOT_SELECT -> HUB -> EXPEDITION` contract and W27 has passed after aligning its stale Build Tools assertion to authoritative `toolchain.lock=36.1.0`. Foundation and the other triggered affected regression workflows on the current candidate must remain green.

After these checks, `sign/w28-production` is fast-forwarded, never force-pushed, to the exact current `v1.0.0-dev1` HEAD. The resulting new production APK must match the established production certificate fingerprint `114bb489ccfdcd7137b70aeb3230bbdd29af08f0e3155ee817419e1afd8269ef`. Any signer mismatch, build failure, package/version drift or 16 KB failure blocks R04 continuation.

## Prevention compliance

- `PR-001=PASS`: previous successful signing run and current branch/workflow state were read back before any signing-branch mutation.
- `PR-002=PASS`: no no-op/trigger-only commit is used; the signing branch is moved only when a new product artifact is actually required.
- `PR-004=PASS`: uploaded production artifact identity contains both `github.run_id` and `github.run_attempt`.
- `PR-007=PASS`: authoritative Android Build Tools and package/version selectors are aligned to `toolchain.lock` and the same W28 workflow used for the first successful production artifact.

`PREVENTION_COMPLIANCE_STATUS=PASS`
