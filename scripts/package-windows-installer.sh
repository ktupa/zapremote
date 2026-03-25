#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/opt/zap-remote"
BUILD_DIR="$ROOT_DIR/installer/build"
SOURCE_EXE="${1:-}"
OUTPUT_NAME="${2:-ZAPRemote-Setup-v3.exe}"
VERSION_LABEL="${3:-3.0.0}"

if [[ -z "$SOURCE_EXE" ]]; then
  echo "Uso: $0 /caminho/para/rustdesk.exe [nome-do-instalador.exe] [versao]"
  exit 1
fi

if [[ ! -f "$SOURCE_EXE" ]]; then
  echo "Arquivo nao encontrado: $SOURCE_EXE"
  exit 1
fi

if ! command -v makensis >/dev/null 2>&1; then
  echo "makensis nao encontrado no PATH"
  exit 1
fi

tmp_script="$(mktemp "$BUILD_DIR/zap-remote-XXXXXX.nsi")"
cleanup() {
  rm -f "$tmp_script"
}
trap cleanup EXIT

cp -f "$SOURCE_EXE" "$BUILD_DIR/rustdesk.exe"
cp -f "$ROOT_DIR/client/RustDesk2.toml" "$BUILD_DIR/RustDesk2.toml"

sed \
  -e "s/!define PRODUCT_VERSION \"2.0.0\"/!define PRODUCT_VERSION \"$VERSION_LABEL\"/" \
  -e "s/OutFile \"ZAPRemote-Setup-v2.exe\"/OutFile \"$OUTPUT_NAME\"/" \
  "$BUILD_DIR/ZAPRemote-v2.nsi" > "$tmp_script"

pushd "$BUILD_DIR" >/dev/null
makensis "$(basename "$tmp_script")"
popd >/dev/null

echo "Instalador gerado em: $BUILD_DIR/$OUTPUT_NAME"