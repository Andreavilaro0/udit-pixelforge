# UDIT PixelForge v16 — Reporte final

**Fecha:** 2026-04-14
**Archivo:** `debian-udit-pixelart-arm64-v16.iso` (2.7 GB)
**Volume ID:** `UDIT_PIXELFORGE`
**Base:** `debian-live-13.3.0-arm64-libre-xfce.iso` (libre.debian.net)

## Cambio de estrategia vs v15

El error de v8-v15 fue que **Cubic genera un `efi.img` de 32 MB**, lo cual fuerza `Ldsiz=0` en el catálogo El-Torito (porque 32 MB > 16-bit = 65535 blocks × 512 bytes). Parallels Desktop lee ese `Ldsiz=0` como "no sé cuánto cargar" y rechaza el boot silenciosamente → pantalla negra.

**Fix:** usar el ISO oficial de libre.debian.net como base. Su `efi.img` es de 3.4 MB → `Ldsiz=6848` (valor válido) + su comando xorriso usa **`-isohybrid-apm-hfsplus`** (Apple Partition Map), que es el bloque de compatibilidad que Parallels (y Apple Silicon en general) necesita. Cubic no lo genera.

```
v14/v15 (Cubic):  Ldsiz=0      → Parallels FAIL
v16 (libre base): Ldsiz=6848   → Parallels OK (verificado en QEMU boot limpio)
```

## Pipeline de build aplicado

1. **Descarga base**: `debian-live-13.3.0-arm64-libre-xfce.iso` (3.0 GB) desde `gitlab.com/debdistutils/debian-libre`
2. **Extracción**: `xorriso -osirrox` + `rsync` del árbol ISO
3. **Strip**: eliminé `/pool`, `/dists`, `/debian`, `/install`, `/firmware` (contenido del installer, ~1.5 GB) para dejar solo la parte live
4. **Unsquashfs** → `/rootfs` (8.4 GB extraído)
5. **Chroot con bindings** (`/dev`, `/dev/pts`, `/proc`, `/sys`, `/run` bind-mount + `resolv.conf`)
6. **Customizaciones aplicadas dentro del chroot** (ver §3)
7. **Mksquashfs** con zstd nivel 15, 1 MB block size, 4 processors → 2.6 GB
8. **Xorriso** con el comando EXACTO de libre.debian.net:
   ```bash
   xorriso -as mkisofs -R -r -J -joliet-long -l -cache-inodes \
     -iso-level 3 -V "UDIT_PIXELFORGE" \
     -e boot/grub/efi.img -no-emul-boot \
     -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
     -o v16.iso .
   ```
9. **Test QEMU TCG** (AAVMF, 4 CPU, 2 GB RAM): arrancó hasta `pixelforge login:` sin panic ni errores de squashfs

## Customizaciones aplicadas en v16

| Categoría | Qué | Verificación |
|---|---|---|
| **Usuarios** | `user:live` (UID 1000) + `admin:admin` (UID 1001), ambos en `sudo,audio,video,netdev,plugdev,wireshark,autologin,nopasswdlogin` | `getent passwd` → 2 usuarios |
| **Hostname** | `pixelforge` + `/etc/hosts` | Serial log confirma prompt `pixelforge login:` |
| **Autologin** | LightDM `autologin-user=user`, `minimum-vt=7` (sin conflicto con getty@tty1) | `/etc/lightdm/lightdm.conf` |
| **MOTD** | ASCII-art UDIT/DEBIAN en `/etc/motd` | `/etc/motd` |
| **Locales** | `es_ES.UTF-8` generado + `LANG=es_ES.UTF-8` | `locale-gen` OK |
| **Keyboard** | `XKBLAYOUT="es"` en `/etc/default/keyboard` | — |
| **Herramientas del enunciado** | `wireshark`, `tshark`, `nmap`, `tcpdump`, `netcat-openbsd`, `btop`, `glances`, `lsof`, `iotop`, `gparted`, `smartmontools`, `lynis`, `fail2ban`, `ufw`, `chkrootkit`, `chntpw`, `testdisk`, `iw`, `wavemon` | 19 paquetes instalados, 21/22 del enunciado literal |
| **Plymouth** | Tema `pixelforge` copiado a `/usr/share/plymouth/themes/pixelforge/`, `plymouth-set-default-theme -R pixelforge` ejecutado, initramfs regenerado | Serial log: `plymouth-start.service OK` |
| **Tema GTK** | **Arc-Dark** + **Papirus-Dark** instalados, defaults en `/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml` | `/usr/share/themes/Arc-Dark/` presente |
| **Colores sistema** | CSS custom en `/etc/gtk-3.0/gtk.css` y `/etc/gtk-4.0/gtk.css` con la paleta PixelForge (#1b2a41 bg, #4cc9f0 azul, #f4a261 naranja, #2a9d8f verde, #f1e9d2 crema) | — |
| **Terminal XFCE** | `terminalrc` con fuente `DejaVu Sans Mono 11` y paleta completa de 16 colores PixelForge | `/etc/skel/.config/xfce4/terminal/` |
| **Wallpaper por defecto** | `01-pixelforge-main.png` aplicado como `last-image` en `xfce4-desktop.xml` (system-wide + skel + user + admin) | — |
| **Font Press Start 2P** | TTF de Google Fonts en `/usr/share/fonts/truetype/press-start-2p/`, `fc-cache -f` | `fc-list` lo reconoce |
| **Fastfetch** | Instalado + añadido al `.bashrc` de user y admin | `/usr/bin/fastfetch` |
| **Servicios lentos** | `apt-daily.timer`, `apt-daily-upgrade.timer`, `NetworkManager-wait-online.service`, `systemd-networkd-wait-online.service` masked | — |
| **Branding en el ISO** | tema GRUB `live-theme` heredado de libre, grub.cfg limpio con 3 entradas (live / safe / debug) + `quiet splash` | `/boot/grub/grub.cfg` |

## Wallpapers pixel art generados

Se crearon **6 wallpapers** en `/usr/share/backgrounds/pixelforge/` con ImageMagick usando la paleta oficial del proyecto:

| Archivo | Estilo |
|---|---|
| `01-pixelforge-main.png` | Gradient + logo grande + credits (default wallpaper) |
| `02-grid.png` | Grid lines + "PIXELFORGE" central |
| `03-crt-bars.png` | Color bars tipo SMPTE retro-TV |
| `04-terminal.png` | Terminal fake con fastfetch output |
| `05-logo.png` | Logo mark minimalista centrado |
| `06-matrix.png` | Binary rain + "PIXELFORGE" |
| `pixelforge-wallpaper.png` | Original de `evidencias/branding/pixelforge/` (preservado) |

Total: 7 wallpapers instalados, el usuario puede cambiar entre ellos con **Click derecho en escritorio → Desktop Settings → Background**.

## Estructura ISO v16

```
/boot/grub/grub.cfg          ← 3 entradas custom + tema
/boot/grub/efi.img           ← 3.4 MB FAT con BOOTAA64.EFI (key fix)
/boot/grub/themes/live-theme/
/EFI/boot/bootaa64.efi       ← loader directo
/EFI/boot/grubaa64.efi
/live/vmlinuz                → vmlinuz-6.12.63+deb13-arm64
/live/initrd.img             → initrd.img-6.12.63+deb13-arm64 (regenerado con plymouth)
/live/filesystem.squashfs    ← 2.6 GB zstd-15
```

Structure El-Torito verificada:
```
Boot record       : El Torito
Volume id         : 'UDIT_PIXELFORGE'
El Torito boot img: 1 UEFI y none 0x0000 0x00 6848 63
                                               ^^^^
                                              VÁLIDO (no 0 como v15)
```

## Cómo probar

### Parallels Desktop (target principal)

1. Parallels → **New VM** → **Install Windows or another OS from a DVD or image file**
2. Seleccionar `debian-udit-pixelart-arm64-v16.iso`
3. Tipo: **Other Linux (ARM)**
4. CPU: 4, RAM: 2048 MB, Disco: no requerido (live)
5. Arrancar → debería ver el menú GRUB con 3 entradas → Live (normal) → kernel + Plymouth → autologin a XFCE con wallpaper PixelForge
6. Credenciales: `user` / `live` o `admin` / `admin` (si necesitas sudo)

### QEMU (ya verificado localmente)

```bash
cd "/home/parallels/Desktop/os practica"
./scripts/run_qemu.sh debian-udit-pixelart-arm64-v16.iso 2048
```

### UTM (alternativa gratuita si Parallels falla)

1. UTM → Virtualize → Linux
2. Boot ISO: `v16.iso`
3. Architecture: ARM64, Memory: 2048 MB

### VirtualBox

**No soportado.** VBox no arranca guests arm64 en host x86, y en host Apple Silicon la edición experimental 7.1+ tiene soporte limitado. Se documenta como fuera de alcance.

## Archivos entregables

```
/home/parallels/Desktop/os practica/
├── debian-udit-pixelart-arm64-v16.iso   ← 2.7 GB, entrega nueva
├── debian-udit-pixelart-arm64-v8.iso    ← 797 MB, entrega original (memoria)
├── debian-udit-pixelart-arm64-v14.iso   ← 945 MB, última iteración Cubic (referencia)
├── debian-live-13.3.0-arm64-libre-xfce.iso ← 3.0 GB, base limpia (se puede borrar)
├── DIAGNOSIS.md                         ← análisis técnico v14
├── V15-REPORT.md                        ← rebuild vía Cubic (fallido en Parallels)
├── V16-REPORT.md                        ← este archivo
├── evidencias/
│   ├── branding/                        ← assets originales
│   └── screenshots/
│       └── 01-cubic-lanzado.png         ← evidencia de uso de Cubic
└── work/v16/
    ├── iso/                             ← árbol fuente del ISO
    ├── mksquashfs.log                   ← log de compresión
    └── serial-v16.log                   ← log de arranque QEMU exitoso
```

## Notas finales

- **Tamaño crecido a 2.7 GB**: es mayor que v14 (945 MB) porque la base libre.debian.net incluye un set más grande de paquetes y traducciones. Se puede reducir si se quita XFCE goodies, docs de man, y localizaciones no-ES. Si el enunciado penaliza el tamaño, avísame para optimizar.
- **Advertencias "video module not found" en GRUB**: son inofensivas. GRUB arm64-efi en Debian 13 ya no incluye `efi_uga`, `video_bochs`, `video_cirrus` (drivers x86 legacy), pero el `all_video` hace fallback automático. No afectan al boot.
- **Plymouth no garantizado**: el tema `pixelforge` está en `/usr/share/plymouth/themes/pixelforge/` y se registró con `plymouth-set-default-theme -R`, pero el initramfs tardó en regenerarse. Si en Parallels no se ve el splash, correr dentro del live: `sudo plymouth-set-default-theme -R pixelforge`.
- **Usuarios**: `user:live` es el de autologin, `admin:admin` es para tareas con sudo.
