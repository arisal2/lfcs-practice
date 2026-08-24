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
: "${VM_CPUS:?Missing VM_CPUS in vm.conf}"
: "${VM_MEMORY:?Missing VM_MEMORY in vm.conf}"
: "${SSH_HOST_PORT:?Missing SSH_HOST_PORT in vm.conf}"

IMAGE_DIR="$ROOT_DIR/$IMAGE_DIR_REL"
INSTANCE_DIR="$ROOT_DIR/$INSTANCE_DIR_REL"
SEED_ISO="$ROOT_DIR/$SEED_ISO_REL"
BASE_IMAGE="$IMAGE_DIR/$BASE_IMAGE_NAME"
OVERLAY_IMAGE="$INSTANCE_DIR/$OVERLAY_IMAGE_NAME"

for required_file in "$BASE_IMAGE" "$SEED_ISO"; do
  if [[ ! -r "$required_file" ]]; then
    echo "Missing readable file: $required_file" >&2
    exit 1
  fi
done

mkdir -p "$INSTANCE_DIR"

if [[ ! -f "$OVERLAY_IMAGE" ]]; then
    qemu-img create \
    -f qcow2 \
    -F qcow2 \
    -b "$BASE_IMAGE" \
    "$OVERLAY_IMAGE" \
    "$OVERLAY_SIZE"
fi

COMMAND_ARGS=(
  -accel hvf
  -m "$VM_MEMORY"
  -smp "$VM_CPUS"
  -drive "if=virtio,format=qcow2,file=$OVERLAY_IMAGE"
  -drive "if=virtio,format=raw,readonly=on,file=$SEED_ISO"
  -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:${SSH_HOST_PORT}-:22"
  -nographic
)

case "$(uname -m)" in
  arm64)
    FIRMWARE="$(brew --prefix qemu)/share/qemu/edk2-aarch64-code.fd"

    if [[ ! -r "$FIRMWARE" ]]; then
      echo "Missing readable firmware: $FIRMWARE" >&2
      exit 1
    fi

    exec qemu-system-aarch64 \
      -machine virt,highmem=off \
      -cpu host \
      -bios "$FIRMWARE" \
      "${COMMAND_ARGS[@]}"
    ;;
  x86_64)
    exec qemu-system-x86_64 \
      -machine q35 \
      -cpu host \
      "${COMMAND_ARGS[@]}"
    ;;
  *)
    echo "Unsupported host architecture: $(uname -m)" >&2
    exit 1
    ;;
esac
