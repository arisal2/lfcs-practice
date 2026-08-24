#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CONFIG_FILE="$ROOT_DIR/config/vm.conf"

if [[ ! -r "$CONFIG_FILE" ]]; then
  echo "Missing readable configuration: $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"

: "${IMAGE_DIR_REL:?Missing IMAGE_DIR_REL in vm.conf}"
: "${INSTANCE_DIR_REL:?Missing INSTANCE_DIR_REL in vm.conf}"
: "${SEED_DATA_DIR_REL:?Missing SEED_DATA_DIR_REL in vm.conf}"
: "${SEED_ISO_REL:?Missing SEED_ISO_REL in vm.conf}"
: "${BASE_IMAGE_NAME:?Missing BASE_IMAGE_NAME in vm.conf}"
: "${ARM64_IMAGE_URL:?Missing ARM64_IMAGE_URL in vm.conf}"
: "${AMD64_IMAGE_URL:?Missing AMD64_IMAGE_URL in vm.conf}"

IMAGE_DIR="$ROOT_DIR/$IMAGE_DIR_REL"
INSTANCE_DIR="$ROOT_DIR/$INSTANCE_DIR_REL"
SEED_DATA_DIR="$ROOT_DIR/$SEED_DATA_DIR_REL"
SEED_ISO="$ROOT_DIR/$SEED_ISO_REL"
BASE_IMAGE="$IMAGE_DIR/$BASE_IMAGE_NAME"
PARTIAL_IMAGE="${BASE_IMAGE}.partial"

mkdir -p \
  "$IMAGE_DIR" \
  "$INSTANCE_DIR" \
  "$(dirname "$SEED_ISO")"

for seed_file in \
  "$SEED_DATA_DIR/user-data" \
  "$SEED_DATA_DIR/meta-data"; do
  if [[ ! -r "$seed_file" ]]; then
    echo "Missing readable cloud-init file: $seed_file" >&2
    exit 1
  fi
done

case "$(uname -m)" in
  arm64)
    IMAGE_URL="$ARM64_IMAGE_URL"
    ;;
  x86_64)
    IMAGE_URL="$AMD64_IMAGE_URL"
    ;;
  *)
    echo "Unsupported host architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

is_qcow2() {
  qemu-img info "$1" \
    | grep -q 'file format: qcow2'
}

if [[ -f "$BASE_IMAGE" ]]; then
  if ! is_qcow2 "$BASE_IMAGE"; then
    echo "Existing base image is not valid qcow2: $BASE_IMAGE" >&2
    exit 1
  fi

  echo "Reusing existing base image: $BASE_IMAGE"
else
  rm -f "$PARTIAL_IMAGE"

  echo "Downloading Ubuntu base image..."

  if ! curl \
    --fail \
    --location \
    --progress-bar \
    --output "$PARTIAL_IMAGE" \
    "$IMAGE_URL"; then
    rm -f "$PARTIAL_IMAGE"
    echo "Base-image download failed." >&2
    exit 1
  fi

  if ! is_qcow2 "$PARTIAL_IMAGE"; then
    rm -f "$PARTIAL_IMAGE"
    echo "Downloaded file is not a valid qcow2 image." >&2
    exit 1
  fi

  mv "$PARTIAL_IMAGE" "$BASE_IMAGE"
fi

rm -f "$SEED_ISO"

hdiutil makehybrid \
  -o "$SEED_ISO" \
  "$SEED_DATA_DIR" \
  -iso \
  -joliet \
  -default-volume-name cidata \
  >/dev/null

echo "Setup complete. Base: $BASE_IMAGE; seed: $SEED_ISO"
