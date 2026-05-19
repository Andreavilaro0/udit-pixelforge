#!/usr/bin/env bash
# ============================================================================
# UDIT PixelForge — Parche v8 → v9
# Añade netcat-openbsd al squashfs live para cerrar el único gap literal del PDF.
# Flujo manual (sin Cubic). Idempotente y reversible.
# Requiere ≥ 4 GB libres en /tmp y ≥ 1 GB RAM libre.
# ============================================================================
set -euo pipefail

ISO_IN="${1:-debian-udit-pixelart-arm64-v8.iso}"
ISO_OUT="${2:-debian-udit-pixelart-arm64-v9.iso}"

WORK="$(mktemp -d -t pixelforge-v9-XXXX)"
trap 'echo "[cleanup] $WORK"; sudo umount -lf "$WORK"/mnt 2>/dev/null || true; sudo rm -rf "$WORK"' EXIT

echo "[1/8] Verificando entradas…"
[[ -f "$ISO_IN" ]] || { echo "ERROR: no existe $ISO_IN"; exit 1; }
command -v unsquashfs >/dev/null || { echo "ERROR: instala squashfs-tools"; exit 1; }
command -v xorriso    >/dev/null || { echo "ERROR: instala xorriso"; exit 1; }

echo "[2/8] Montando ISO de origen…"
mkdir -p "$WORK/mnt" "$WORK/iso" "$WORK/rootfs"
sudo mount -o loop,ro "$ISO_IN" "$WORK/mnt"

echo "[3/8] Copiando árbol ISO…"
sudo rsync -a --exclude=live/filesystem.squashfs "$WORK/mnt/" "$WORK/iso/"
sudo cp "$WORK/mnt/live/filesystem.squashfs" "$WORK/filesystem.squashfs.orig"
sudo umount "$WORK/mnt"

echo "[4/8] Descomprimiendo squashfs (tarda varios minutos)…"
sudo unsquashfs -f -d "$WORK/rootfs" -processors 2 "$WORK/filesystem.squashfs.orig" >/dev/null

echo "[5/8] Preparando chroot y aplicando parche netcat-openbsd…"
sudo cp /etc/resolv.conf "$WORK/rootfs/etc/resolv.conf"
for m in dev proc sys run; do sudo mount --bind /$m "$WORK/rootfs/$m"; done

sudo chroot "$WORK/rootfs" /bin/bash <<'EOS'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends netcat-openbsd
apt-get clean
rm -rf /var/lib/apt/lists/*
EOS

echo "[6/8] Desmontando bindings…"
for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m"; done

echo "[7/8] Recomprimiendo squashfs (xz, paciencia)…"
sudo mkdir -p "$WORK/iso/live"
sudo mksquashfs "$WORK/rootfs" "$WORK/iso/live/filesystem.squashfs" \
    -comp xz -Xbcj arm -processors 2 -mem 512M -noappend

echo "[7b/8] Actualizando md5sum.txt…"
(cd "$WORK/iso" && sudo bash -c "find . -type f -print0 | xargs -0 md5sum | grep -v boot.catalog > md5sum.txt")

echo "[8/8] Forjando ISO v9 con xorriso…"
sudo xorriso -as mkisofs \
  -r -V "DEBIAN_UDIT_EDITION" -J -l \
  -e boot/grub/efi.img -no-emul-boot \
  -append_partition 2 0xef "$WORK/iso/boot/grub/efi.img" \
  -o "$ISO_OUT" "$WORK/iso/"

echo "[✓] ISO v9 generada: $ISO_OUT"
sha256sum "$ISO_OUT"
ls -lh "$ISO_OUT"
