#!/usr/bin/env bash
# ============================================================================
# UDIT PixelForge - Build v20 menu update
# Reparte sobre v20 actual: añade fzf+chafa, instala iconos pixel art generados
# con Gemini, reemplaza robomenu por la versión fzf, quita fastfetch+banner,
# habilita auto-launch en TTY1.
# ============================================================================
set -euo pipefail

ROOT="/home/parallels/Desktop/os_practica"
ISO_IN="$ROOT/debian-udit-pixelart-arm64-v20-final.iso"
ISO_OUT="$ROOT/debian-udit-pixelart-arm64-v20-final.iso"
ASSETS="$ROOT/scripts/v20-assets"
ICONS="$ASSETS/icons"
WORK="$ROOT/work/v20-menu-build"

echo "[0/9] Limpiando workspace previo"
sudo rm -rf "$WORK"
mkdir -p "$WORK/mnt" "$WORK/iso" "$WORK/rootfs"

trap '
echo "[cleanup]"
sudo umount -lf "$WORK/rootfs/dev/pts" 2>/dev/null || true
for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m" 2>/dev/null || true; done
sudo umount -lf "$WORK/mnt" 2>/dev/null || true
' EXIT

[[ -f "$ISO_IN" ]] || { echo "ERROR no existe $ISO_IN"; exit 1; }
[[ -f "$ASSETS/robomenu" ]] || { echo "ERROR no existe robomenu"; exit 1; }
[[ -d "$ICONS" ]] && [ "$(ls -A $ICONS/*.png 2>/dev/null | wc -l)" -ge 5 ] || { echo "ERROR faltan iconos en $ICONS"; exit 1; }

echo "[1/9] Montando v20 actual"
sudo mount -o loop,ro "$ISO_IN" "$WORK/mnt"

echo "[2/9] Copiando árbol ISO sin squashfs"
sudo rsync -a --exclude=live/filesystem.squashfs "$WORK/mnt/" "$WORK/iso/"
sudo cp "$WORK/mnt/live/filesystem.squashfs" "$WORK/squashfs.v20"
sudo umount "$WORK/mnt"

echo "[3/9] Descomprimiendo squashfs v20 (zstd, ~5 min)"
sudo unsquashfs -f -d "$WORK/rootfs" -processors 2 "$WORK/squashfs.v20" 2>&1 | tail -3
sudo rm -f "$WORK/squashfs.v20"

echo "[4/9] Bindings"
sudo cp /etc/resolv.conf "$WORK/rootfs/etc/resolv.conf"
for m in dev proc sys run; do sudo mount --bind /$m "$WORK/rootfs/$m"; done
sudo mount -t devpts devpts "$WORK/rootfs/dev/pts" 2>/dev/null || true

echo "[5/9] Instalando fzf + chafa en chroot"
sudo chroot "$WORK/rootfs" /bin/bash <<'EOS' 2>&1 | tee /tmp/v20-menu-chroot.log
set +e
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
apt-get update 2>&1 | tail -2

for pkg in fzf chafa; do
    apt-get install -y --no-install-recommends "$pkg" 2>&1 | tail -2
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        echo "OK $pkg"
    else
        echo "MISS $pkg"
    fi
done

apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
EOS
cp /tmp/v20-menu-chroot.log "$ROOT/work/v20-menu-chroot.log"

echo "[6/9] Instalando assets nuevos"
# 1. robomenu nuevo (con fzf+chafa)
sudo install -m 755 "$ASSETS/robomenu" "$WORK/rootfs/usr/local/bin/robomenu"

# 2. Iconos en /usr/share/pixelforge/icons/
sudo mkdir -p "$WORK/rootfs/usr/share/pixelforge/icons"
sudo cp "$ICONS"/*.png "$WORK/rootfs/usr/share/pixelforge/icons/"
ls "$WORK/rootfs/usr/share/pixelforge/icons/"

# 3. Quitar banner anterior (queremos UX limpia)
sudo rm -f "$WORK/rootfs/etc/profile.d/robosec-banner.sh"

# 4. Modificar .bashrc del usuario danielsson para:
#    - Quitar fastfetch (que metía ruido)
#    - Auto-lanzar robomenu en TTY1
BASHRC="$WORK/rootfs/home/danielsson/.bashrc"
if [ -f "$BASHRC" ]; then
    # Backup
    sudo cp "$BASHRC" "$BASHRC.v19-backup"
    # Eliminar fastfetch
    sudo sed -i '/fastfetch/d' "$BASHRC"
    # Asegurar que el block de auto-launch sólo se añade una vez
    if ! grep -q "robomenu auto-launch" "$BASHRC"; then
        sudo bash -c "cat >> '$BASHRC'" <<'BASHEOF'

# === PixelForge v20: robomenu auto-launch en TTY1 (texto puro) ===
if [ "$(tty)" = "/dev/tty1" ]; then
    /usr/local/bin/robomenu
fi
BASHEOF
    fi
fi

# Mismo para /etc/skel/.bashrc por consistencia
SKEL="$WORK/rootfs/etc/skel/.bashrc"
if [ -f "$SKEL" ]; then
    sudo sed -i '/fastfetch/d' "$SKEL"
    if ! grep -q "robomenu auto-launch" "$SKEL"; then
        sudo bash -c "cat >> '$SKEL'" <<'BASHEOF'

# === PixelForge v20: robomenu auto-launch en TTY1 ===
if [ "$(tty)" = "/dev/tty1" ]; then
    /usr/local/bin/robomenu
fi
BASHEOF
    fi
fi

# admin también
ADMINRC="$WORK/rootfs/home/admin/.bashrc"
if [ -f "$ADMINRC" ]; then
    sudo sed -i '/fastfetch/d' "$ADMINRC"
fi

echo "[7/9] Desmontando bindings y regenerando filesystem.packages"
sudo umount -lf "$WORK/rootfs/dev/pts" 2>/dev/null || true
for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m"; done

sudo chroot "$WORK/rootfs" dpkg-query -W -f='${Package}\t${Version}\n' \
    | sudo tee "$WORK/iso/live/filesystem.packages" >/dev/null
echo "  $(wc -l < "$WORK/iso/live/filesystem.packages") paquetes"

echo "[8/9] Comprimiendo squashfs (zstd-22, bloque 1M, ~15-20 min)"
sudo rm -f "$WORK/iso/live/filesystem.squashfs"
sudo mksquashfs "$WORK/rootfs" "$WORK/iso/live/filesystem.squashfs" \
    -comp zstd -Xcompression-level 22 \
    -b 1M \
    -processors 2 -mem 512M -noappend 2>&1 | tail -5

echo "[8b/9] Actualizando md5sum.txt"
(cd "$WORK/iso" && sudo bash -c "find . -type f -print0 | xargs -0 md5sum | grep -v boot.catalog > md5sum.txt")

echo "[9/9] Forjando ISO v20 (con timeout=30 ya en grub.cfg)"
sudo rm -f "$ISO_OUT"
sudo xorriso -as mkisofs \
    -r -V "DEBIAN_UDIT_EDITION_V20" -J -l \
    -e boot/grub/efi.img -no-emul-boot \
    -append_partition 2 0xef "$WORK/iso/boot/grub/efi.img" \
    -o "$ISO_OUT" "$WORK/iso/" 2>&1 | tail -3

sudo chown parallels:parallels "$ISO_OUT"

echo ""
echo "[OK] v20 con menú nuevo generada"
ls -lh "$ISO_OUT"
sha256sum "$ISO_OUT" | tee "$ROOT/evidencias/iso-sha256-v20.txt"

echo "[copia al Mac]"
cp -v "$ISO_OUT" /media/psf/Home/Desktop/debian-udit-pixelart-arm64-v20-final.iso
echo "[CLEANUP]"
sudo rm -rf "$WORK/rootfs"
df -h "$ROOT" | tail -1
