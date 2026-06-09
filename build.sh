#!/usr/bin/env bash
# Local build helper for zmk-config-thumbRotary
#
# Uses the official zmkfirmware/zmk-build-arm Docker image; no west,
# Zephyr SDK, or python tooling needed on the host.
#
# Usage:
#   ./build.sh              # build both halves (left + right)
#   ./build.sh left         # build left only
#   ./build.sh right        # build right only
#   ./build.sh clean        # remove workspace & build outputs
#
# Environment overrides:
#   BOARD=seeeduino_xiao_ble
#   SHIELD_LEFT="thumbRotary_left rgbled_adapter"
#   SHIELD_RIGHT="thumbRotary_right rgbled_adapter"
#   DOCKER_IMAGE=zmkfirmware/zmk-build-arm:stable

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_ROOT="${CONFIG_DIR}/.build"
WORKSPACE="${BUILD_ROOT}/workspace"
OUTPUT="${BUILD_ROOT}/output"

BOARD="${BOARD:-seeeduino_xiao_ble}"
SHIELD_LEFT="${SHIELD_LEFT:-thumbRotary_left rgbled_adapter}"
SHIELD_RIGHT="${SHIELD_RIGHT:-thumbRotary_right rgbled_adapter}"
DOCKER_IMAGE="${DOCKER_IMAGE:-zmkfirmware/zmk-build-arm:stable}"

cmd="${1:-all}"

die() { echo "error: $*" >&2; exit 1; }

[[ "$(command -v docker)" ]] || die "Docker not found. Install Docker Desktop (https://www.docker.com/products/docker-desktop/) and re-run."

if [[ "$cmd" == "clean" ]]; then
  echo "Removing ${BUILD_ROOT}"
  rm -rf "${BUILD_ROOT}"
  exit 0
fi

mkdir -p "${WORKSPACE}" "${OUTPUT}"

# Ensure the config repo is visible inside the workspace as 'config'.
# We bind-mount the config dir into the workspace at a stable path so that
# west.yml's `self.path: config` resolves correctly.
docker_run() {
  docker run --rm \
    -v "${WORKSPACE}":/workspaces/zmk-workspace \
    -v "${CONFIG_DIR}":/workspaces/zmk-workspace/zmk-config:ro \
    -w /workspaces/zmk-workspace \
    "${DOCKER_IMAGE}" \
    bash -lc "$1"
}

# One-time west init + update inside the container (cached across runs).
if [[ ! -d "${WORKSPACE}/.west" ]]; then
  echo "==> Initializing west workspace (one-time, ~1-2 min)"
  docker_run '
    set -e
    cd /workspaces/zmk-workspace
    # Re-create config as a writable copy west can sit alongside.
    rm -rf config
    cp -r zmk-config/config ./config
    west init -l config
    west update --narrow -o=--depth=1
    west zephyr-export
  '
fi

# Sync latest user-config changes (keymap, conf, dts) into the workspace's
# 'config' directory on every run.
docker_run '
  rm -rf /workspaces/zmk-workspace/config
  cp -r /workspaces/zmk-workspace/zmk-config/config /workspaces/zmk-workspace/config
'

build_one() {
  local name="$1" shield="$2"
  echo "==> Building ${name} (board=${BOARD}, shield=${shield})"
  docker_run "
    set -e
    cd /workspaces/zmk-workspace
    west build -s zmk/app -d build/${name} -b ${BOARD} -p auto -- \
      -DZMK_EXTRA_MODULES=/workspaces/zmk-workspace/zmk-config \
      -DZMK_CONFIG=/workspaces/zmk-workspace/config \
      -DSHIELD='${shield}'
  "
  cp "${WORKSPACE}/build/${name}/zephyr/zmk.uf2" "${OUTPUT}/${name}.uf2"
  echo "  ${OUTPUT}/${name}.uf2"
}

case "$cmd" in
  all)
    build_one left "${SHIELD_LEFT}"
    build_one right "${SHIELD_RIGHT}"
    ;;
  left)
    build_one left "${SHIELD_LEFT}"
    ;;
  right)
    build_one right "${SHIELD_RIGHT}"
    ;;
  *)
    die "unknown command: $cmd (expected: all | left | right | clean)"
    ;;
esac

echo "==> Done. UF2 files in ${OUTPUT}/"
