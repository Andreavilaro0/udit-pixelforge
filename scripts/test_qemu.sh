#!/usr/bin/env bash
# Lanzador QEMU ARM64 para probar UDIT PixelForge en GUI.
# Requiere >=2 GB libres en el host.
set -euo pipefail

ISO="${1:-debian-udit-pixelart-arm64-v8.iso}"
RAM="${2:-1024}"
[[ -f "$ISO" ]] || { echo "ERROR: falta $ISO"; exit 1; }

exec qemu-system-aarch64 \
  -machine virt,gic-version=max \
  -accel tcg,thread=multi \
  -cpu max \
  -smp 2 \
  -m "$RAM" \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -device virtio-gpu-pci \
  -device qemu-xhci \
  -device usb-kbd \
  -device usb-mouse \
  -drive if=none,id=cd,file="$ISO",media=cdrom,format=raw \
  -device virtio-blk-pci,drive=cd \
  -display gtk \
  -serial mon:stdio
