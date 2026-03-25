#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-/opt/zap-remote/rustdesk-source}"
ROOT_DIR="/opt/zap-remote"
PATCH_FILE="$ROOT_DIR/patches/rustdesk-source-zapremote.patch"
UPSTREAM_REPO="https://github.com/rustdesk/rustdesk.git"

if [[ ! -f "$PATCH_FILE" ]]; then
  echo "Patch nao encontrado: $PATCH_FILE"
  exit 1
fi

if [[ ! -d "$TARGET_DIR/.git" ]]; then
  echo "Clonando upstream em $TARGET_DIR"
  git clone "$UPSTREAM_REPO" "$TARGET_DIR"
fi

git -C "$TARGET_DIR" apply --check "$PATCH_FILE"
git -C "$TARGET_DIR" apply "$PATCH_FILE"

echo "Patch aplicado em: $TARGET_DIR"