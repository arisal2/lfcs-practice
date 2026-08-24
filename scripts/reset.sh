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
: "${BASE_IMAGE_NAME:?Missing BASE_IMAGE_NAME in vm.conf}"
: "${OVERLAY_IMAGE_NAME:?Missing OVERLAY_IMAGE_NAME in vm.conf}"
: "${OVERLAY_SIZE:?Missing OVERLAY_SIZE in vm.conf}"

IMAGE_DIR="$ROOT_DIR/$IMAGE_DIR_REL"
INSTANCE_DIR="$ROOT_DIR/$INSTANCE_DIR_REL"
BASE_IMAGE="$IMAGE_DIR/$BASE_IMAGE_NAME"
OVERLAY_IMAGE="$INSTANCE_DIR/$OVERLAY_IMAGE_NAME"

if [[ ! -r "$BASE_IMAGE" ]]; then
  echo "Missing readable base image: $BASE_IMAGE" >&2
  echo "Run ./scripts/setup.sh first." >&2
  exit 1
fi

mkdir -p "$INSTANCE_DIR"

rm -f "$OVERLAY_IMAGE"

qemu-img create \
  -f qcow2 \
  -F qcow2 \
  -b "$BASE_IMAGE" \
  "$OVERLAY_IMAGE" \
  "$OVERLAY_SIZE"

echo "VM reset complete: $OVERLAY_IMAGE"