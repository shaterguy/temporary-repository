#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"W28_CONTRACT_FAIL: {message}")


def resolve_res_path(value: str) -> Path:
    require(value.startswith("res://"), f"expected res:// path, got {value!r}")
    return ROOT / value.removeprefix("res://")


def walk_dicts(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk_dicts(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_dicts(child)


toolchain = json.loads((ROOT / "toolchain.lock").read_text(encoding="utf-8"))
identity = toolchain["identity"]
android = toolchain["android"]
require(identity["version_name"] == "1.0.0-dev1", "unexpected version_name")
require(identity["version_code"] == 1, "unexpected version_code")
require(identity["prod_application_id"] == "com.shaterguy.lanternfall", "unexpected PROD application id")
require(identity["dev_application_id"] == "com.shaterguy.lanternfall.dev", "unexpected DEV application id")
require(android["primary_abi"] == "arm64-v8a", "unexpected primary ABI")
require(android["build_tools"] == "35.0.1", "unexpected Android build-tools")

preset_text = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
for literal in (
    'name="Android Production"',
    'platform="Android"',
    'gradle_build/use_gradle_build=false',
    'architectures/armeabi-v7a=false',
    'architectures/arm64-v8a=true',
    'architectures/x86=false',
    'architectures/x86_64=false',
    'version/code=1',
    'version/name="1.0.0-dev1"',
    'package/unique_name="com.shaterguy.lanternfall"',
    'package/signed=true',
    'keystore/debug=""',
    'keystore/debug_password=""',
    'keystore/release=""',
    'keystore/release_user=""',
    'keystore/release_password=""',
):
    require(literal in preset_text, f"missing export preset contract: {literal}")
require("androiddebugkey" not in preset_text.lower(), "debug signing identity must not be embedded")
require(not re.search(r'keystore/(?:release|release_user|release_password)=".+"', preset_text), "release signing material must stay out of source")

workflow_path = ROOT / ".github/workflows/w28-production-signing.yml"
workflow = workflow_path.read_text(encoding="utf-8")
require("workflow_dispatch:" in workflow, "production signing workflow must be manually gated")
require("\n  push:" not in workflow and "\n  pull_request:" not in workflow, "production signing workflow must not auto-run on source events")
require("if: github.ref == 'refs/heads/v1.0.0-dev1'" in workflow, "production signer must be ref-gated to the canonical dev branch")
for secret_name in (
    "LANTERNFALL_PROD_KEYSTORE_B64",
    "LANTERNFALL_PROD_KEY_ALIAS",
    "LANTERNFALL_PROD_KEY_PASSWORD",
    "LANTERNFALL_PROD_CERT_SHA256",
):
    require(f"secrets.{secret_name}" in workflow, f"missing protected secret reference {secret_name}")
require("GODOT_ANDROID_KEYSTORE_RELEASE_PATH" in workflow, "Godot release keystore env override missing")
require("GODOT_ANDROID_KEYSTORE_RELEASE_USER" in workflow, "Godot release alias env override missing")
require("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" in workflow, "Godot release password env override missing")
require("apksigner" in workflow and "--print-certs" in workflow, "APK certificate verification missing")
require("zipalign" in workflow and "-P 16" in workflow, "16 KB zip alignment verification missing")
require("github.run_attempt" in workflow, "artifact identity must include run attempt")
require("androiddebugkey" not in workflow.lower(), "debug-key fallback must not exist in production workflow")
require("keytool -genkey" not in workflow.lower(), "workflow must not generate replacement signing keys per run")
require("-storepass:env KEY_PASSWORD" in workflow, "keystore password must not be passed as a command-line value")

for pattern in ("*.jks", "*.keystore", "*.p12", "*.pem", "*.key"):
    require(not any(ROOT.rglob(pattern)), f"signing/private-key file committed: {pattern}")

content_manifest = json.loads((ROOT / "content_manifest.json").read_text(encoding="utf-8"))
release_gate = content_manifest.get("release_gate", {})
require(release_gate.get("placeholder_assets_required") == 0, "placeholder release gate changed")
require(release_gate.get("license_record_required_for_every_runtime_asset") is True, "runtime asset license gate disabled")

manifest_groups = 0
for node in walk_dicts(content_manifest):
    runtime_manifest_values = [
        value for key, value in node.items()
        if "runtime_manifest" in key and isinstance(value, str) and value.startswith("res://")
    ]
    if not runtime_manifest_values:
        continue
    license_values = [
        value for key, value in node.items()
        if "license_record" in key and isinstance(value, str) and value.startswith("res://")
    ]
    require(license_values, f"runtime manifest group lacks a license record: {runtime_manifest_values}")
    for license_value in license_values:
        require(resolve_res_path(license_value).is_file(), f"missing license record {license_value}")
    for runtime_manifest_value in runtime_manifest_values:
        manifest_path = resolve_res_path(runtime_manifest_value)
        require(manifest_path.is_file(), f"missing runtime manifest {runtime_manifest_value}")
        manifest_data = json.loads(manifest_path.read_text(encoding="utf-8"))
        for manifest_node in walk_dicts(manifest_data):
            require(manifest_node.get("placeholder") is not True, f"placeholder asset in {runtime_manifest_value}")
            if "placeholder_count" in manifest_node:
                require(manifest_node["placeholder_count"] == 0, f"placeholder_count nonzero in {runtime_manifest_value}")
        manifest_groups += 1

require(manifest_groups >= 8, f"too few licensed runtime manifest groups checked: {manifest_groups}")
print("TEST_CONTRACT=w28-production-signing-contract-v1")
print("W28_PROD_PACKAGE=com.shaterguy.lanternfall")
print("W28_VERSION_NAME=1.0.0-dev1")
print("W28_VERSION_CODE=1")
print(f"W28_LICENSED_RUNTIME_MANIFESTS={manifest_groups}")
print("W28_SECRET_IN_SOURCE=NONE")
print("W28_DEBUG_SIGNING_FALLBACK=NONE")
print("W28_RELEASE_CONTRACT=PASS")
