#!/usr/bin/env bash
# UDIT PixelForge — Lanzador QEMU ARM64 con firmware UEFI real (AAVMF/EDK2)
# Uso: ./scripts/run_qemu.sh [iso] [ram_MB]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO="${1:-$ROOT/debian-udit-pixelart-arm64-v14.iso}"
RAM="${2:-3072}"

[[ -f "$ISO" ]] || { echo "ERROR: no existe '$ISO'"; exit 1; }

CODE=/usr/share/AAVMF/AAVMF_CODE.fd
VARS_SRC=/usr/share/AAVMF/AAVMF_VARS.fd
VARS="$ROOT/work/bootfix/VARS-run.fd"

if [[ ! -f "$CODE" || ! -f "$VARS_SRC" ]]; then
    echo "ERROR: falta firmware AAVMF. Instalar con: sudo apt install qemu-efi-aarch64"
    exit 1
fi

mkdir -p "$(dirname "$VARS")"
cp "$VARS_SRC" "$VARS"

echo "[run_qemu] ISO  = $ISO"
echo "[run_qemu] RAM  = ${RAM}M"
echo "[run_qemu] Firm = AAVMF (EDK2 strict UEFI, equiv. Parallels/VBox)"
echo "[run_qemu] Tarda 2-3 min en TCG arm64 puro (sin KVM)"
echo

exec qemu-system-aarch64 \
    -name "UDIT PixelForge" \
    -machine virt,gic-version=max \
    -accel tcg,thread=multi,tb-size=1024 \
    -cpu max -smp 4 -m "$RAM" \
    -drive if=pflash,format=raw,readonly=on,file="$CODE" \
    -drive if=pflash,format=raw,file="$VARS" \
    -device virtio-gpu-pci \
    -device qemu-xhci -device usb-kbd -device usb-tablet \
    -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
    -drive if=none,id=cd,file="$ISO",media=cdrom,format=raw,cache=unsafe \
    -device virtio-blk-pci,drive=cd,bootindex=0 \
    -display sdl \
    -serial mon:stdio
