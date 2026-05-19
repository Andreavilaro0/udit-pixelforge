#!/usr/bin/env bash
# ============================================================================
# UDIT PixelForge - Build v19 -> v20
# Anade paquetes de seguridad/robotica de la nueva guia RoboSecOS adaptada
# a Debian 13 ARM64, sin tocar branding ni autologin de PixelForge.
#
# Paquetes nuevos:
#   Seguridad: masscan, nikto, hydra, john, hashcat, aircrack-ng, gobuster, whois
#   Robotica:  avrdude, minicom, screen, picocom, python3-pip, esptool
#   Sistema:   vim, git, tmux, htop, neofetch, figlet, lolcat
#
# Scripts nuevos:
#   /usr/local/bin/robomenu              (menu interactivo whiptail)
#   /etc/profile.d/robosec-banner.sh     (banner figlet+lolcat al login TTY)
#
# Flujo: mount ISO -> rsync arbol -> unsquashfs -> chroot apt -> mksquashfs -> xorriso
# ============================================================================
set -euo pipefail

ROOT="/home/parallels/Desktop/os_practica"
ISO_IN="${1:-$ROOT/debian-udit-pixelart-arm64-v19-final.iso}"
ISO_OUT="${2:-$ROOT/debian-udit-pixelart-arm64-v20-final.iso}"
ASSETS="$ROOT/scripts/v20-assets"

WORK="$ROOT/work/v20-build"
LOG="$ROOT/work/v20-build.log"

echo "[0/9] Preparando workspace en $WORK"
sudo rm -rf "$WORK"
mkdir -p "$WORK/mnt" "$WORK/iso" "$WORK/rootfs"
> "$LOG"

trap 'echo "[cleanup]"; for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m" 2>/dev/null || true; done; sudo umount -lf "$WORK/mnt" 2>/dev/null || true' EXIT

echo "[1/9] Verificando entradas"
[[ -f "$ISO_IN" ]] || { echo "ERROR: no existe $ISO_IN"; exit 1; }
[[ -f "$ASSETS/robomenu" ]] || { echo "ERROR: falta $ASSETS/robomenu"; exit 1; }
[[ -f "$ASSETS/robosec-banner.sh" ]] || { echo "ERROR: falta $ASSETS/robosec-banner.sh"; exit 1; }
for t in unsquashfs mksquashfs xorriso rsync sha256sum; do
    command -v $t >/dev/null || { echo "ERROR: falta $t"; exit 1; }
done

echo "[2/9] Montando ISO v19"
sudo mount -o loop,ro "$ISO_IN" "$WORK/mnt"

echo "[3/9] Copiando arbol ISO (sin squashfs)"
sudo rsync -a --exclude=live/filesystem.squashfs "$WORK/mnt/" "$WORK/iso/"
sudo cp "$WORK/mnt/live/filesystem.squashfs" "$WORK/squashfs.orig"
sudo umount "$WORK/mnt"

echo "[4/9] Descomprimiendo squashfs (~5 min)"
sudo unsquashfs -f -d "$WORK/rootfs" -processors 2 "$WORK/squashfs.orig" 2>&1 | tail -3
sudo rm "$WORK/squashfs.orig"

echo "[5/9] Bindings y resolv.conf"
sudo cp /etc/resolv.conf "$WORK/rootfs/etc/resolv.conf"
for m in dev proc sys run; do sudo mount --bind /$m "$WORK/rootfs/$m"; done

echo "[6/9] Instalando paquetes en chroot"
sudo chroot "$WORK/rootfs" /bin/bash <<'EOS' 2>&1 | tee -a /tmp/v20-chroot.log
set -e
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

echo "::actualizando indices apt"
apt-get update

echo "::instalando bloque SEGURIDAD"
apt-get install -y --no-install-recommends \
    masscan nikto hydra john hashcat aircrack-ng gobuster whois \
    || echo "WARN: algun paquete de seguridad fallo"

echo "::instalando bloque ROBOTICA/HARDWARE"
apt-get install -y --no-install-recommends \
    avrdude minicom screen picocom python3-pip \
    || echo "WARN: algun paquete de robotica fallo"

echo "::instalando bloque SISTEMA/COSMETICOS"
apt-get install -y --no-install-recommends \
    vim git tmux htop neofetch figlet lolcat \
    || echo "WARN: algun paquete cosmetico fallo"

echo "::instalando esptool via pip (no esta en apt arm64)"
pip3 install --break-system-packages esptool 2>&1 | tail -5 \
    || echo "WARN: esptool pip fallo (no critico)"

echo "::limpiando cache apt"
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*.deb

echo "::verificando binarios instalados"
for b in masscan nikto hydra john hashcat aircrack-ng gobuster whois \
         avrdude minicom screen picocom pip3 \
         vim git tmux htop neofetch figlet lolcat esptool; do
    if command -v $b >/dev/null 2>&1; then echo "OK $b"; else echo "MISS $b"; fi
done
EOS

cp /tmp/v20-chroot.log "$LOG"

echo "[7/9] Copiando scripts robomenu y banner"
sudo install -m 755 "$ASSETS/robomenu" "$WORK/rootfs/usr/local/bin/robomenu"
sudo install -m 755 "$ASSETS/robosec-banner.sh" "$WORK/rootfs/etc/profile.d/robosec-banner.sh"

echo "[7b/9] Verificando scripts en sitio"
ls -la "$WORK/rootfs/usr/local/bin/robomenu" "$WORK/rootfs/etc/profile.d/robosec-banner.sh"

echo "[7c/9] Desmontando bindings"
for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m"; done

echo "[8/9] Regenerando filesystem.packages"
sudo chroot "$WORK/rootfs" dpkg-query -W -f='${Package}\t${Version}\n' \
    | sudo tee "$WORK/iso/live/filesystem.packages" >/dev/null
wc -l "$WORK/iso/live/filesystem.packages"

echo "[8b/9] Comprimiendo squashfs nuevo (xz arm, ~10-15 min)"
sudo mksquashfs "$WORK/rootfs" "$WORK/iso/live/filesystem.squashfs" \
    -comp xz -Xbcj arm -processors 2 -mem 512M -noappend 2>&1 | tail -5

echo "[8c/9] Actualizando md5sum.txt"
(cd "$WORK/iso" && sudo bash -c "find . -type f -print0 | xargs -0 md5sum | grep -v boot.catalog > md5sum.txt")

echo "[9/9] Forjando ISO v20"
sudo xorriso -as mkisofs \
    -r -V "DEBIAN_UDIT_EDITION_V20" -J -l \
    -e boot/grub/efi.img -no-emul-boot \
    -append_partition 2 0xef "$WORK/iso/boot/grub/efi.img" \
    -o "$ISO_OUT" "$WORK/iso/" 2>&1 | tail -5

sudo chown parallels:parallels "$ISO_OUT"

echo ""
echo "[OK] v20 generada"
ls -lh "$ISO_OUT"
sha256sum "$ISO_OUT"

echo ""
echo "[LIMPIEZA] Borrando $WORK/rootfs (libera ~3GB)"
sudo rm -rf "$WORK/rootfs"
df -h "$ROOT" | tail -1
