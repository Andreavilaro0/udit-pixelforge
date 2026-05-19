#!/usr/bin/env bash
# ============================================================================
# UDIT PixelForge - Build v20 (FIX: zstd-22 1M blocks)
# Rebuild completo con la MISMA config de squashfs que v19 (zstd-22, bloques 1M)
# El intento previo con xz/BCJ arm/128K produjo corrupción de descompresión en
# el kernel del guest (-> kernel panic "Attempted to kill init").
# ============================================================================
set -euo pipefail

ROOT="/home/parallels/Desktop/os_practica"
ISO_IN="$ROOT/debian-udit-pixelart-arm64-v19-final.iso"
ISO_OUT="$ROOT/debian-udit-pixelart-arm64-v20-final.iso"
ASSETS="$ROOT/scripts/v20-assets"
WORK="$ROOT/work/v20-build"

echo "[0/9] Limpiando workspace previo"
sudo rm -rf "$WORK"
mkdir -p "$WORK/mnt" "$WORK/iso" "$WORK/rootfs"

trap '
echo "[cleanup]"
sudo umount -lf "$WORK/rootfs/dev/pts" 2>/dev/null || true
for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m" 2>/dev/null || true; done
sudo umount -lf "$WORK/mnt" 2>/dev/null || true
' EXIT

echo "[1/9] Verificando entradas"
[[ -f "$ISO_IN" ]] || { echo "ERROR no existe $ISO_IN"; exit 1; }
[[ -f "$ASSETS/robomenu" ]] || { echo "ERROR no existe robomenu"; exit 1; }
[[ -f "$ASSETS/robosec-banner.sh" ]] || { echo "ERROR no existe banner"; exit 1; }

echo "[2/9] Montando ISO v19 base"
sudo mount -o loop,ro "$ISO_IN" "$WORK/mnt"

echo "[3/9] Copiando arbol ISO sin squashfs"
sudo rsync -a --exclude=live/filesystem.squashfs "$WORK/mnt/" "$WORK/iso/"
sudo cp "$WORK/mnt/live/filesystem.squashfs" "$WORK/squashfs.v19"
sudo umount "$WORK/mnt"

echo "[4/9] Descomprimiendo squashfs v19 (zstd, ~5 min)"
sudo unsquashfs -f -d "$WORK/rootfs" -processors 2 "$WORK/squashfs.v19" 2>&1 | tail -3
sudo rm -f "$WORK/squashfs.v19"

echo "[5/9] Setup chroot con bindings + /dev/pts"
sudo cp /etc/resolv.conf "$WORK/rootfs/etc/resolv.conf"
for m in dev proc sys run; do sudo mount --bind /$m "$WORK/rootfs/$m"; done
sudo mount -t devpts devpts "$WORK/rootfs/dev/pts" 2>/dev/null || true

echo "[6/9] Instalando paquetes (uno por uno, tolerante)"
sudo chroot "$WORK/rootfs" /bin/bash <<'EOS' 2>&1 | tee /tmp/v20-fix-chroot.log
set +e
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

apt-get update

# Lista filtrada: solo paquetes confirmados existentes en trixie/main arm64
PKGS=(
    # Seguridad (7 confirmados)
    masscan hydra john hashcat aircrack-ng gobuster whois
    # Robotica/Hardware (5)
    avrdude minicom screen picocom python3-pip
    # Sistema/utilidades (6)
    vim git tmux htop figlet lolcat
)

INSTALLED=()
SKIPPED=()
for pkg in "${PKGS[@]}"; do
    apt-get install -y --no-install-recommends "$pkg" >/tmp/apt-out 2>&1
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        echo "OK $pkg"
        INSTALLED+=("$pkg")
    else
        echo "MISS $pkg"
        tail -3 /tmp/apt-out | sed 's/^/   /'
        SKIPPED+=("$pkg")
    fi
done

# esptool via pip
pip3 install --break-system-packages esptool >/dev/null 2>&1 && echo "OK esptool(pip)" || echo "MISS esptool(pip)"

echo ""
echo "INSTALADOS (${#INSTALLED[@]}): ${INSTALLED[*]}"
echo "SALTADOS  (${#SKIPPED[@]}): ${SKIPPED[*]}"

apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
EOS
cp /tmp/v20-fix-chroot.log "$ROOT/work/v20-fix-chroot.log"

echo "[6b/9] Instalando scripts robomenu y banner"
sudo install -m 755 "$ASSETS/robomenu" "$WORK/rootfs/usr/local/bin/robomenu"
sudo install -m 755 "$ASSETS/robosec-banner.sh" "$WORK/rootfs/etc/profile.d/robosec-banner.sh"

echo "[6c/9] Desmontando bindings"
sudo umount -lf "$WORK/rootfs/dev/pts" 2>/dev/null || true
for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m"; done

echo "[7/9] Regenerando filesystem.packages"
sudo chroot "$WORK/rootfs" dpkg-query -W -f='${Package}\t${Version}\n' \
    | sudo tee "$WORK/iso/live/filesystem.packages" >/dev/null
echo "  $(wc -l < "$WORK/iso/live/filesystem.packages") paquetes"

echo "[8/9] Comprimiendo squashfs (zstd-22, bloque 1M, ~15-20 min)"
echo "      [CRITICO: misma config que v19 - el kernel arm64 falla con xz/BCJ-arm]"
sudo rm -f "$WORK/iso/live/filesystem.squashfs"
sudo mksquashfs "$WORK/rootfs" "$WORK/iso/live/filesystem.squashfs" \
    -comp zstd -Xcompression-level 22 \
    -b 1M \
    -processors 2 -mem 512M -noappend 2>&1 | tail -5

echo "[8b/9] Actualizando md5sum.txt"
(cd "$WORK/iso" && sudo bash -c "find . -type f -print0 | xargs -0 md5sum | grep -v boot.catalog > md5sum.txt")

echo "[9/9] Forjando ISO v20"
sudo rm -f "$ISO_OUT"
sudo xorriso -as mkisofs \
    -r -V "DEBIAN_UDIT_EDITION_V20" -J -l \
    -e boot/grub/efi.img -no-emul-boot \
    -append_partition 2 0xef "$WORK/iso/boot/grub/efi.img" \
    -o "$ISO_OUT" "$WORK/iso/" 2>&1 | tail -5

sudo chown parallels:parallels "$ISO_OUT"
echo ""
echo "[OK] v20 FIXED generada"
ls -lh "$ISO_OUT"
sha256sum "$ISO_OUT" | tee "$ROOT/evidencias/iso-sha256-v20.txt"

echo ""
echo "[CLEANUP] Borrando rootfs temporal"
sudo rm -rf "$WORK/rootfs"
df -h "$ROOT" | tail -1
