#!/usr/bin/env bash
set -euo pipefail

readonly FONT_COMMIT="4efc2774c63917927efe769ca845def6bd6debae"
readonly FONT_URL="https://raw.githubusercontent.com/google/fonts/${FONT_COMMIT}/ofl/notosanskr/NotoSansKR%5Bwght%5D.ttf"
readonly FONT_SHA256="194018e6b2b293a7964f037b25c0249ce1418bc9ab3c971060a03aa57861e252"
readonly FONT_DIR="assets/runtime/fonts"
readonly FONT_PATH="${FONT_DIR}/NotoSansKR-wght.ttf"

mkdir -p "$FONT_DIR"

if [[ -s "$FONT_PATH" ]]; then
  actual_sha256="$(sha256sum "$FONT_PATH" | awk '{print $1}')"
  if [[ "$actual_sha256" == "$FONT_SHA256" ]]; then
    echo "UI_FONT_SOURCE_COMMIT=$FONT_COMMIT"
    echo "UI_FONT_SHA256=$actual_sha256"
    echo "UI_FONT_READY=PASS"
    exit 0
  fi
  rm -f "$FONT_PATH"
fi

tmp_font="$(mktemp "${FONT_DIR}/.NotoSansKR-wght.ttf.XXXXXX")"
trap 'rm -f "$tmp_font"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 "$FONT_URL" --output "$tmp_font"
actual_sha256="$(sha256sum "$tmp_font" | awk '{print $1}')"
echo "UI_FONT_SOURCE_COMMIT=$FONT_COMMIT"
echo "UI_FONT_SHA256=$actual_sha256"
if [[ "$actual_sha256" != "$FONT_SHA256" ]]; then
  echo "::error::Pinned Noto Sans KR SHA-256 mismatch" >&2
  exit 1
fi
mv "$tmp_font" "$FONT_PATH"
trap - EXIT
test -s "$FONT_PATH"
echo "UI_FONT_READY=PASS"
