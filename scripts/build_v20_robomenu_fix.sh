#!/usr/bin/env bash
# Reemplaza el robomenu en v20 ISO. NO toca paquetes, solo el script.
set -euo pipefail

ROOT="/home/parallels/Desktop/os_practica"
ISO_IN="$ROOT/debian-udit-pixelart-arm64-v20-final.iso"
ISO_OUT="$ROOT/debian-udit-pixelart-arm64-v20-final.iso"
ASSETS="$ROOT/scripts/v20-assets"
WORK="$ROOT/work/v20-rm-fix"

echo "[0] Limpieza workspace"
sudo rm -rf "$WORK"
mkdir -p "$WORK/mnt" "$WORK/iso" "$WORK/rootfs"

trap 'sudo umount -lf "$WORK/mnt" 2>/dev/null || true' EXIT

echo "[1] Mount v20 actual"
sudo mount -o loop,ro "$ISO_IN" "$WORK/mnt"

echo "[2] rsync árbol sin squashfs"
sudo rsync -a --exclude=live/filesystem.squashfs "$WORK/mnt/" "$WORK/iso/"
sudo cp "$WORK/mnt/live/filesystem.squashfs" "$WORK/sq.old"
sudo umount "$WORK/mnt"

echo "[3] unsquashfs (~5 min)"
sudo unsquashfs -f -d "$WORK/rootfs" -processors 2 "$WORK/sq.old" 2>&1 | tail -2
sudo rm "$WORK/sq.old"

echo "[4] Reemplazar robomenu (único cambio)"
sudo install -m 755 "$ASSETS/robomenu" "$WORK/rootfs/usr/local/bin/robomenu"
sudo head -50 "$WORK/rootfs/usr/local/bin/robomenu" | tail -10

echo "[5] mksquashfs zstd-22 1M (~15 min)"
sudo rm -f "$WORK/iso/live/filesystem.squashfs"
sudo mksquashfs "$WORK/rootfs" "$WORK/iso/live/filesystem.squashfs" \
    -comp zstd -Xcompression-level 22 -b 1M \
    -processors 2 -mem 512M -noappend 2>&1 | tail -3

echo "[6] md5sum"
(cd "$WORK/iso" && sudo bash -c "find . -type f -print0 | xargs -0 md5sum | grep -v boot.catalog > md5sum.txt")

echo "[7] xorriso"
sudo rm -f "$ISO_OUT"
sudo xorriso -as mkisofs \
    -r -V "DEBIAN_UDIT_EDITION_V20" -J -l \
    -e boot/grub/efi.img -no-emul-boot \
    -append_partition 2 0xef "$WORK/iso/boot/grub/efi.img" \
    -o "$ISO_OUT" "$WORK/iso/" 2>&1 | tail -3

sudo chown parallels:parallels "$ISO_OUT"
ls -lh "$ISO_OUT"
sha256sum "$ISO_OUT" | tee "$ROOT/evidencias/iso-sha256-v20.txt"

echo "[8] Copia al Mac"
cp -v "$ISO_OUT" /media/psf/Home/Desktop/debian-udit-pixelart-arm64-v20-final.iso

echo "[9] cleanup"
sudo rm -rf "$WORK"
df -h "$ROOT" | tail -1
