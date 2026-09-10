# W28 production signing and first-install lineage

Task: `SR-20260909-150106-PPO12Y`
Continuation: `SR-20260910-121926-5B5U4L`
Baseline branch: `v1.0.0-dev1`
Launcher-repair input baseline: `9d1743676e6c17fd573675d5065e346bef9546ea`
Test contract: `w28-production-signing-contract-v3`

## Contract preflight

- `TEST_CONTRACT_PREFLIGHT=VALID`
- `ACTION_PREFLIGHT=VALID`
- Original signer mechanism remains `SECURITY_CLASS=HIGH_RISK_OPERATION`; launcher-only repair has `SECURITY_DELTA=NONE` because it does not change the key, certificate, secret backend, package identity, permissions or trust boundary.
- Existing gameplay, save schema, world schema and package identities remain unchanged.
- The production candidate must use explicit LANTERNFALL launcher branding and must not fall through to Godot engine default icons.
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

## Launcher branding gate

The Android package uses project-original launcher art rooted at the W13 cold-twilight / warm-lantern visual grammar:

- Project/main icon: `res://assets/branding/launcher_main.svg`
- Adaptive foreground: `res://assets/branding/launcher_adaptive_foreground.svg`
- Adaptive background: `res://assets/branding/launcher_adaptive_background.svg`
- Adaptive monochrome/themed icon: `res://assets/branding/launcher_adaptive_monochrome.svg`
- Source direction: `res://assets/source/w28/LAUNCHER_BRANDING_DIRECTION.md`
- Provenance/license: `res://assets/licenses/W28_ORIGINAL_BRANDING.md`

`tests/ci/check_w28_release_contract.py` requires all four 512×512 SVG sources, explicit `application/config/icon`, all Android launcher icon preset fields, the source and provenance records, zero Godot default `res://icon.svg` usage and the existing placeholder/license gates. Missing branding now fails in STATIC_PREFLIGHT before signer secrets are materialized.

## Durable signing boundary

The first user-installable production APK and every rebuilt candidate in the same production lineage must be signed by the same durable non-debug key. Every later production in-place update must continue that certificate lineage. Protected material is injected only at GitHub Actions runtime through repository-level protected secrets or an equivalent remote secret backend.

Required protected values:

- `LANTERNFALL_PROD_KEYSTORE_B64`: base64 encoding of the durable production keystore bytes.
- `LANTERNFALL_PROD_KEY_ALIAS`: key alias stored in that keystore.
- `LANTERNFALL_PROD_KEY_PASSWORD`: keystore/key password.
- `LANTERNFALL_PROD_CERT_SHA256`: expected SHA-256 fingerprint for the production signing certificate.

The production workflow never creates a replacement signing key. It materializes the protected keystore only under `/tmp`, verifies the signer fingerprint, uploads only APK plus non-secret metadata, and removes the keystore in an `always()` cleanup step.

## Proven signer state

The durable signer is already proven by prior successful W28 runs. The certificate lineage remains SHA-256 `114bb489ccfdcd7137b70aeb3230bbdd29af08f0e3155ee817419e1afd8269ef`. Launcher repair must reuse that exact lineage; a new key or fallback signer is forbidden.

The prior APK from source SHA `9d1743676e6c17fd573675d5065e346bef9546ea` passed package/version/signature/16 KB checks but is rejected as the final product candidate because its export emitted `No project icon specified` and therefore could fall through to engine-default launcher branding. Its functional/runtime evidence remains reusable outside launcher/package surface impact.

## Remote production workflow

`.github/workflows/w28-production-signing.yml` is triggered only by a push to `sign/w28-production` and has `contents: read` permission. Before any signer secret is used it fetches `v1.0.0-dev1` and requires the signing-branch HEAD to equal the current dev HEAD exactly. A stale or independently modified signing branch fails closed.

The workflow tiers are:

1. CANDIDATE_SYNC: require exact SHA equality with current `v1.0.0-dev1`.
2. STATIC_PREFLIGHT: validate W28 source contract, explicit launcher branding, pinned Godot/toolchain hashes, production identity and no-source-secret rule.
3. SECRET_GATE: require all four durable signer values and validate the expected certificate fingerprint shape without printing secrets.
4. ARTIFACT_BUILD: install the pinned Godot 4.7.2 editor/export templates and Android Build Tools `36.1.0`, materialize the protected keystore only under `/tmp`, and perform `--export-release` using the release-keystore environment overrides.
5. ARTIFACT_VERIFY: verify package/version with `aapt`, APK signature and certificate fingerprint with `apksigner`, 16 KB ZIP/native ELF compatibility with `zipalign`/`readelf`, and record APK SHA-256 and size.
6. PUBLISH_DELIVER: upload only the APK and non-secret metadata with run-ID/run-attempt-specific artifact identity.

## Runtime asset/license gate

The existing runtime-manifest audit still walks all runtime groups declared by `content_manifest.json`, requires each group to declare an existing project license record and rejects placeholders. Launcher branding is packaging-specific and is checked separately against its W28 source/provenance records, so it does not distort gameplay content counts.

## Current repair gate

Only launcher/package surface and the W28 release contract are stale. Existing R01 visual gameplay review, R02 load soak, W25 touch-first path, W27 performance/build-tool alignment and R04 gameplay/touch/save/resize evidence remain reusable because no gameplay, save, input, performance, dependency, package identity or signing lineage changes.

After the updated `v1.0.0-dev1` candidate passes foundation and W28 contract CI, `sign/w28-production` is fast-forwarded, never force-pushed, to the exact same HEAD. The resulting new production APK must match certificate SHA-256 `114bb489ccfdcd7137b70aeb3230bbdd29af08f0e3155ee817419e1afd8269ef`, retain package/version/API/16 KB compatibility and contain the explicit launcher branding. Any signer mismatch, build failure, package/version drift, icon preflight failure or 16 KB failure blocks final verification.

## Prevention compliance

- `PR-001`: use read-only repository/workflow/run state before every mutation; no probe workflow or failure-inducing run.
- `PR-002`: the repair commit carries actual launcher/config/contract changes; no no-op trigger commit is permitted.
- `PR-004`: production artifact identity contains both `github.run_id` and `github.run_attempt`; changed source identity requires a new run rather than rerunning an old attempt.

Final compliance is determined from the actual diff, run identities and readback evidence.
