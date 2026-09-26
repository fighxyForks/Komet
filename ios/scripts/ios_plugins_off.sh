#!/bin/sh
set -eu

mode="${1:?}"

plugins_define="S09NRVRfUExVR0lOUz1mYWxzZQ=="
if [ -n "${DART_DEFINES:-}" ]; then
  DART_DEFINES="${DART_DEFINES},${plugins_define}"
else
  DART_DEFINES="${plugins_define}"
fi
export DART_DEFINES

/bin/sh "${FLUTTER_ROOT:?}/packages/flutter_tools/bin/xcode_backend.sh" "$mode"

strip_tree() {
  if [ -n "$1" ] && [ -d "$1" ]; then
    rm -rf "$1"
  fi
}

if [ -n "${BUILT_PRODUCTS_DIR:-}" ]; then
  strip_tree "${BUILT_PRODUCTS_DIR}/App.framework/flutter_assets/assets/plugins"
fi

if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${FRAMEWORKS_FOLDER_PATH:-}" ]; then
  strip_tree "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/App.framework/flutter_assets/assets/plugins"
fi

if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${WRAPPER_NAME:-}" ]; then
  strip_tree "${TARGET_BUILD_DIR}/${WRAPPER_NAME}/flutter_assets/assets/plugins"
fi

if [ "$mode" = "embed_and_thin" ] && [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${EXECUTABLE_PATH:-}" ]; then
  binary="${TARGET_BUILD_DIR}/${EXECUTABLE_PATH}"
  if [ -f "$binary" ] && nm -gU "$binary" 2>/dev/null | grep -q 'frbgen_fjs_'; then
    echo "error: iOS binary links the fjs runtime" >&2
    exit 1
  fi
fi