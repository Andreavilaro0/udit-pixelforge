#!/usr/bin/env bash
# ============================================================================
# UDIT PixelForge - Build v20 (RESUME)
# Continua desde un rootfs ya extraido en /work/v20-build/rootfs/
# Instala paquetes uno por uno para tolerar paquetes inexistentes (nikto, neofetch)
# ============================================================================
set -euo pipefail

ROOT="/home/parallels/Desktop/os_practica"
ISO_OUT="${1:-$ROOT/debian-udit-pixelart-arm64-v20-final.iso}"
ASSETS="$ROOT/scripts/v20-assets"
WORK="$ROOT/work/v20-build"
LOG="$ROOT/work/v20-resume.log"

> "$LOG"

[[ -d "$WORK/rootfs" ]] || { echo "ERROR: $WORK/rootfs no existe, usa build_v20.sh primero"; exit 1; }
[[ -d "$WORK/iso" ]] || { echo "ERROR: $WORK/iso no existe"; exit 1; }

trap 'echo "[cleanup]"; for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m" 2>/dev/null || true; done' EXIT

echo "[1/6] Bindings"
sudo cp /etc/resolv.conf "$WORK/rootfs/etc/resolv.conf"
for m in dev proc sys run; do
    mountpoint -q "$WORK/rootfs/$m" || sudo mount --bind /$m "$WORK/rootfs/$m"
done
# /dev/pts es importante para apt
sudo mount -t devpts devpts "$WORK/rootfs/dev/pts" 2>/dev/null || true

echo "[2/6] Instalando paquetes UNO POR UNO (tolerante a fallos)"
sudo chroot "$WORK/rootfs" /bin/bash <<'EOS' 2>&1 | tee -a /tmp/v20-resume-chroot.log
set +e
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

# Lista completa de paquetes deseados (los ya instalados se saltan automaticamente con apt)
PKGS=(
    # Seguridad
    masscan hydra john hashcat aircrack-ng gobuster whois
    nikto                    # puede no existir en trixie - se intenta igual
    # Robotica/Hardware (mayoria ya instalados, idempotente)
    avrdude minicom screen picocom python3-pip
    # Sistema/cosmeticos
    vim git tmux htop figlet lolcat
    neofetch fastfetch       # neofetch no esta en trixie; fastfetch es el reemplazo
)

INSTALLED=()
SKIPPED=()

for pkg in "${PKGS[@]}"; do
    echo ":: probando $pkg"
    if apt-get install -y --no-install-recommends "$pkg" 2>&1 | tail -3; then
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            echo "  OK $pkg"
            INSTALLED+=("$pkg")
        else
            echo "  MISS $pkg (no quedo instalado)"
            SKIPPED+=("$pkg")
        fi
    else
        echo "  MISS $pkg (apt fallo)"
        SKIPPED+=("$pkg")
    fi
done

echo ""
echo "=========================================="
echo "INSTALADOS (${#INSTALLED[@]}): ${INSTALLED[*]}"
echo "SALTADOS  (${#SKIPPED[@]}): ${SKIPPED[*]}"
echo "=========================================="

# esptool via pip si no esta
if ! command -v esptool >/dev/null 2>&1; then
    echo ":: esptool via pip"
    pip3 install --break-system-packages esptool 2>&1 | tail -3 || echo "  WARN pip esptool fallo"
fi

# Verificacion final de binarios
echo ""
echo "=== VERIFICACION DE BINARIOS ==="
for b in masscan nikto hydra john hashcat aircrack-ng gobuster whois \
         avrdude minicom screen picocom pip3 esptool \
         vim git tmux htop neofetch fastfetch figlet lolcat; do
    if command -v $b >/dev/null 2>&1; then
        printf "  OK   %s -> %s\n" "$b" "$(command -v $b)"
    else
        printf "  MISS %s\n" "$b"
    fi
done

# Limpieza
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*.deb
EOS

cp /tmp/v20-resume-chroot.log "$LOG"

echo "[3/6] Copiando scripts robomenu y banner"
sudo install -m 755 "$ASSETS/robomenu" "$WORK/rootfs/usr/local/bin/robomenu"
sudo install -m 755 "$ASSETS/robosec-banner.sh" "$WORK/rootfs/etc/profile.d/robosec-banner.sh"
ls -la "$WORK/rootfs/usr/local/bin/robomenu" "$WORK/rootfs/etc/profile.d/robosec-banner.sh"

echo "[3b/6] Desmontando bindings"
sudo umount -lf "$WORK/rootfs/dev/pts" 2>/dev/null || true
for m in run sys proc dev; do sudo umount -lf "$WORK/rootfs/$m"; done

echo "[4/6] Regenerando filesystem.packages"
sudo chroot "$WORK/rootfs" dpkg-query -W -f='${Package}\t${Version}\n' \
    | sudo tee "$WORK/iso/live/filesystem.packages" >/dev/null
echo "  $(wc -l < "$WORK/iso/live/filesystem.packages") paquetes registrados"

# borra squashfs viejo si existe
sudo rm -f "$WORK/iso/live/filesystem.squashfs"

echo "[5/6] Comprimiendo squashfs (xz arm, ~10-15 min)"
sudo mksquashfs "$WORK/rootfs" "$WORK/iso/live/filesystem.squashfs" \
    -comp xz -Xbcj arm -processors 2 -mem 512M -noappend 2>&1 | tail -5

echo "[5b/6] Actualizando md5sum.txt"
(cd "$WORK/iso" && sudo bash -c "find . -type f -print0 | xargs -0 md5sum | grep -v boot.catalog > md5sum.txt")

echo "[6/6] Forjando ISO v20"
sudo rm -f "$ISO_OUT"
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
echo "[LIMPIEZA] Borrando rootfs (libera ~3GB)"
sudo rm -rf "$WORK/rootfs"
df -h "$ROOT" | tail -1
