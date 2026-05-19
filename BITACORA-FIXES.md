# UDIT PixelForge — Bitácora de iteraciones y fixes

**Autores:** Andrea Ávila & Iván Herrera González
**Fechas:** 2026-04-14 → 2026-04-15
**Punto de partida:** `debian-udit-pixelart-arm64-v14.iso` construida con Cubic (ver `MEMORIA.md` §9)
**Entrega final:** `debian-udit-pixelart-arm64-v18-final.iso` (883 MB)

---

## 1. Estado inicial (v8–v14)

### Lo que funcionaba
- ISO construida con Cubic 2026.02 sobre base Debian 13 arm64 live
- squashfs con 778 paquetes, XFCE 4.18, LightDM, Plymouth
- Todas las herramientas del enunciado instaladas
- Arranca en QEMU (`./scripts/run_qemu.sh`) hasta `pixelforge login:`

### Lo que NO funcionaba (reportado por el usuario)
1. **No arranca en Parallels Desktop** (Mac Apple Silicon) — pantalla negra tras logo Parallels
2. **No arranca en VirtualBox Oracle** — falla inmediatamente
3. **Arranque lentísimo** en QEMU (>2 min parado en `live-config.service`)
4. **Autologin se pasa del login** — no entra a XFCE
5. **Customizaciones no se ven** — wallpaper, tema, Plymouth splash ausentes

---

## 2. Fase de diagnóstico (DIAGNOSIS.md)

Re-extracción del squashfs de v14 y análisis serial boot log. Hallazgos clave:

### 2.1 Error crítico del empaquetado xorriso
El script `scripts/patch_v9_netcat.sh` usaba:
```bash
xorriso -as mkisofs -r -V "DEBIAN_UDIT_EDITION" -J -l \
  -e boot/grub/efi.img -no-emul-boot \
  -append_partition 2 0xef boot/grub/efi.img \
  -o out.iso ./
```

Faltaban `-isohybrid-gpt-basdat` y `-isohybrid-apm-hfsplus`. Consecuencia:
- **`efi.img` pesaba 32 MB** (Cubic default) → El-Torito catálogo se veía forzado a usar **`Ldsiz=0`** porque 32 MB / 512 bytes = 65536 blocks > 65535 (16-bit max)
- Parallels Desktop lee `Ldsiz=0` como "no sé cuánto cargar" → rechaza el arranque silenciosamente
- QEMU es permisivo con ese valor → sí arrancaba

### 2.2 VirtualBox arm64 en host x86 no existe
Oracle VBox solo soporta guests arm64 en hosts Apple Silicon con edición experimental 7.1.x. **No hay fix posible**, se descarta del alcance.

### 2.3 Plymouth tema real vs declarado
- `plymouthd.conf` decía `Theme=pixelforge`
- `pixelforge.script` usaba `logo.png` pre-renderizado con texto "PixelForge OS"
- El initramfs embebía ese logo, no había background real

### 2.4 LightDM VT conflict
`/etc/lightdm/lightdm.conf` tenía `minimum-vt=1` → LightDM pelea con `getty@tty1`, lo que causaba que el autologin "se pasara" del prompt.

### 2.5 Usuario fantasma
`/home/danielsson/` residual de la ISO base (creator Daniel Baumann) + `/home/user/` vacío sin skel XFCE.

### 2.6 Paquete `fonts-press-start-2p` NO existe en Debian 13
Fue removido del repo. Hay que bajar el TTF directo de Google Fonts.

---

## 3. Intentos de rebuild (v15)

### v15 intento 1: con Cubic-style xorriso + flags completas
Añadí `-eltorito-alt-boot`, `-appended_part_as_gpt`, `-isohybrid-gpt-basdat` al comando. Resultado: **rompió el boot en QEMU** — se quedaba en `BdsDxe: loading Boot0001` sin avanzar. El warning "Boot image load size exceeds 65535 blocks" seguía apareciendo porque `efi.img` seguía siendo 32 MB.

### v15 intento 2: simplificar xorriso al mínimo
Volví al comando `-e boot/grub/efi.img -append_partition 2 0xef ...`. Funcionó en QEMU pero **seguía fallando en Parallels** porque el `Ldsiz=0` persistía.

### v15 intento 3: squashfs compression
Primero probé `mksquashfs -comp xz -Xbcj arm`. Kernel panic con `SQUASHFS error: xz decompression failed`. **La base libre usa `zstd` con blocks de 1 MB**, no xz. Cambié a `-comp zstd -Xcompression-level 15 -b 1M` → funcionó.

---

## 4. Cambio de estrategia: base limpia libre.debian.net (v16)

### 4.1 Decisión
Cubic produce un `efi.img` fijo de 32 MB que fuerza `Ldsiz=0` → **no hay forma de arreglarlo manteniendo la base Cubic**. Descargo `debian-live-13.3.0-arm64-libre-xfce.iso` (libre.debian.net) que es conocida por arrancar en Parallels.

### 4.2 Comando canónico extraído de `.disk/mkisofs` de la libre ISO
```
xorriso -as mkisofs -R -r -J -joliet-long -l -cache-inodes -iso-level 3 \
  -v -A "Debian Libre Live 13.3.0 xfce arm64" \
  -V "d-libre-13.3.0-xfce-arm64" \
  --modification-date=... \
  -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat \
  -isohybrid-apm-hfsplus \
  -o out.iso binary
```

**Flag clave descubierta:** `-isohybrid-apm-hfsplus` añade un **Apple Partition Map** al ISO. Parallels Desktop sobre Apple Silicon es estricto y lo necesita. Cubic nunca lo genera.

Y su `efi.img` pesa **3.4 MB**, no 32 MB → `Ldsiz = 6848` (valor válido de 16 bits).

### 4.3 Resultado v16
Estructura El-Torito verificada: `El Torito boot img : 1 UEFI y none 0x0000 0x00 6848 63`

Esa es la diferencia crítica vs. v15 (`Ldsiz 0`). **Esta ISO ya arranca en Parallels.**

---

## 5. Problemas de contenido post-arranque (v16 → v18)

### 5.1 XFCE session crash
Después de arreglar el boot, la sesión se trababa al iniciar. Causas encontradas:

1. **`xfce4-session` se había removido** por un `apt autoremove` de una ronda de slim anterior. Reinstalado explícitamente.
2. **`light-locker` se activaba al login** → mostraba password prompt encima del escritorio. Usuario veía "Escriba la contraseña" y creía que era el greeter. Purgado.
3. **`calamares-desktop-icon.desktop`** en autostart → lanzaba el instalador al login. Removido.
4. **2 polkit agents en autostart** (`polkit-mate-*` y `polkit-ukui-*`) → conflicto. Reducido a uno.
5. **`xfce4-panel.xml` referenciaba `.desktop` files inexistentes** (`wireshark.desktop`, `mousepad.desktop`, `ristretto.desktop`, `htop.desktop`) → panel crasheaba al cargar. Reescrito con solo launchers válidos.

### 5.2 Plymouth no mostraba el portal
- Mi primer rebuild usó el PNG original de 7.4 MB → no entraba en initramfs correctamente
- Además no re-ejecuté `plymouth-set-default-theme -R pixelforge` tras cada cambio → initramfs desactualizado
- **Fix:** convertir a JPG 186 KB, rewrite del script para usar `background.jpg` fullscreen, `update-initramfs -u` y copiar el nuevo initrd a `/iso/live/`

### 5.3 LightDM greeter background equivocado
El usuario reportó que veía el UDIT Gemini building en el login, no el castle que yo había puesto. Al final:
- El usuario aclaró con 3 imágenes específicas:
  - **Portal** (`panel de carga.png`) → Plymouth boot splash
  - **Hotel Andrea+Iván** (`inicio-secion.webp`) → LightDM greeter
  - **UDIT building** (`walpaper.webp`) → Desktop wallpaper
- Yo había estado usando el fantasy castle como login bg — malentendido. Reemplacé por el hotel.

### 5.4 Login screen tapaba las caras
Con la caja del form centrada, tapaba el texto "Andrea e Iván crearon esto :)" del hotel. **Fix:** `position = 50%,center 78%,center` en `lightdm-gtk-greeter.conf` → caja 78% hacia abajo.

### 5.5 Contraseñas no funcionaban
Varias rondas de `chpasswd` en el chroot. Las passwords se perdían en reinstalaciones. Al final fijé:
```bash
echo "danielsson:root" | chpasswd
echo "user:live" | chpasswd
echo "admin:admin" | chpasswd
echo "root:root" | chpasswd
```

### 5.6 Fullname extraño en login
Creé `danielsson` con GECOS `"Daniel Baumann (Debian Live)"` → el greeter mostraba "Daniel Baumann" en lugar de `danielsson`. **Fix:** `sed` sobre `/etc/passwd` para dejar GECOS vacío.

### 5.7 Navbar no aparecía
Primera vez el usuario logueó, el panel no cargó. Causa: el XML del panel estaba en `/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/` pero xfce4-panel lee de `~/.config/xfce4/xfconf/...`. El primer login copia de skel, pero el usuario puede haber sesionado antes del skel correcto. **Fix:** Script `pixelforge-firstrun.sh` en autostart que copia el panel.xml a `$HOME/.config/...` en el primer arranque.

### 5.8 Wallpaper duplicado
Por aspect ratio mismatch: imagen 1080x607 en pantalla 1920x1200 → tiling. **Fix:** reescalar con ImageMagick a 1920x1200 con letterboxing + `image-style=5` (zoom).

### 5.9 Resolución chica
MacBook Air 13" + Parallels sin Parallels Tools = 1024x768 default. **Fixes:**
- Kernel cmdline: `video=1920x1080`
- Autostart script ejecuta `xrandr --output $(first connected) --mode 1920x1080`
- `Xft.DPI=120` para HiDPI

---

## 6. Problemas de transferencia al Mac

### 6.1 SHA incorrecto al copiar
Al descargar el ISO del VM al Mac vía OneDrive/shared folder inicial, el archivo se corrompía:
- Origen VM: `790f45ef4038c929...`
- Tras copiar: `6b8933bb2d34e2be...`

### 6.2 Fix: shared folder de Parallels
Activé Share Mac folders en la configuración de la VM (menu Configure → Options → Sharing) → `/media/psf/Home/` aparece dentro del VM → `cp` directo al `~/Downloads/` del Mac. SHA verifica idéntico.

---

## 7. Purgas de slim (evolución del tamaño)

| Versión | Tamaño | Qué cambió |
|---|---|---|
| v14 (Cubic original) | 945 MB | base |
| v15 (mi rebuild xz roto) | — | corrupto squashfs |
| v16 libre base full | 2.8 GB | libre.debian.net completo |
| v16 stripped | 2.0 GB | quité firefox, docs, man, locales |
| v16 slim2 | 1.2 GB | purgué fonts-noto-*, qt-webengine, libwebkit, ibus, mesa-vulkan, gcc |
| v17 | 1.2 GB | con Gemini wallpapers + danielsson |
| **v18 final** | **883 MB** | + purgado mythes, anthy, flite, samba-libs, libgdal, libz3, cpp-14, libgs10, hunspell-ko, dnnl, espeak, speech-dispatcher, breeze-cursor |

---

## 8. Customizaciones aplicadas (estado final v18)

### Usuarios
| Usuario | Password | UID | Grupos |
|---|---|---|---|
| `danielsson` | `root` | 1002 | sudo, wireshark, audio, video, netdev, plugdev, autologin, nopasswdlogin |
| `user` | `live` | 1000 | sudo, wireshark, audio, video, netdev, plugdev, autologin |
| `admin` | `admin` | 1001 | sudo, wireshark, audio, video, netdev, plugdev |
| `root` | `root` | 0 | — |

### Tema Catppuccin Mocha Blue
- **GTK theme:** `catppuccin-mocha-blue-standard+default` (desde `github.com/catppuccin/gtk` v1.0.3)
- **Icon theme:** Papirus-Dark
- **Cursor:** Adwaita (breeze purgado en slim final)
- **Terminal palette:** paleta Mocha 16 colores
- **CSS custom** en `/etc/gtk-3.0/gtk.css` y `/etc/gtk-4.0/gtk.css` con variables `@base`, `@mantle`, `@blue`, `@peach`, etc.
- **Archivos originales del gist** en `/etc/pixelforge/themes/catppuccin/` y `/usr/share/color-schemes/`
- **LightDM greeter glass** con CSS en `/etc/lightdm/lightdm-gtk-greeter-custom.css` — login form rounded + shadow + backdrop oscuro translúcido

### Wallpapers
| Dónde | Archivo | Origen |
|---|---|---|
| Plymouth boot splash | `/usr/share/plymouth/themes/pixelforge/background.jpg` | `panel de carga.png` (portal pixel art) |
| LightDM greeter | `/usr/share/backgrounds/pixelforge/login.jpg` | `inicio-secion.webp` (hotel Andrea+Iván) |
| Desktop XFCE | `/usr/share/backgrounds/pixelforge/wallpaper.jpg` | `walpaper.webp` (UDIT building) |

### Panel XFCE (dock de 2 barras)
**Top bar** (26 px, Catppuccin crust alpha 0.85):
- Menú "PixelForge" con icono
- Tasklist
- Systray
- Clock centrado

**Bottom dock** (52 px, Catppuccin mantle alpha 0.82, floating):
1. xfce4-appfinder
2. Thunar
3. xfce4-terminal
4. Wireshark
5. GParted
6. btop (wrapper)
7. glances (wrapper)
8. nmap (wrapper)
9. lynis (wrapper)
10. chkrootkit (wrapper)
11. wavemon (wrapper)
12. testdisk (wrapper)

Los "wrappers" son `.desktop` files en `/usr/share/applications/pixelforge-*.desktop` que lanzan cada CLI dentro de `xfce4-terminal --hold -e "comando"`.

### Herramientas del enunciado (verificadas instaladas)
`wireshark`, `tshark`, `nmap`, `tcpdump`, `netcat-openbsd`, `btop`, `glances`, `lsof`, `iotop`, `gparted`, `smartmontools`, `lynis`, `fail2ban`, `ufw`, `chkrootkit`, `chntpw`, `testdisk`, `iw`, `wavemon`, `network-manager`, `nftables`

### Plymouth theme (retro game loading)
Script `/usr/share/plymouth/themes/pixelforge/pixelforge.script`:
- Background JPG del portal a pantalla completa, escalado cover
- Barra de progreso con `progress_box.png` + `progress_bar.png` abajo
- Sin texto pre-renderizado

### Autostart limpio
Sólo lo esencial en `/etc/xdg/autostart/`:
- gnome-keyring (ssh, secrets, pkcs11)
- nm-applet
- pulseaudio
- xfce4-notifyd
- xfce4-power-manager
- xfsettingsd
- xfce4-clipman
- xdg-user-dirs
- xfce-polkit (polkit-mate agent)
- pixelforge-firstrun.sh (nuestro script)

### Lo que se QUITÓ del autostart (causaba el trabón)
- `light-locker.desktop` (screen locker)
- `calamares-desktop-icon.desktop` (installer)
- `orca-autostart.desktop`
- `im-launch.desktop`
- `at-spi-dbus-bus.desktop`
- `polkit-ukui-authentication-agent-1.desktop`
- `xfce4-notes-autostart.desktop`
- `print-applet.desktop`
- `xiccd.desktop`
- `spice-vdagent.desktop`

---

## 9. Timeline de iteraciones

| ISO | Fecha | Tamaño | Estado |
|---|---|---|---|
| v8 | 12 abr | 797 MB | entrega memoria original (Cubic) |
| v14 | 12 abr 15:35 | 945 MB | última iteración Cubic pre-rebuild |
| v15 | 14 abr 22:02 | 927 MB | rebuild Cubic-base con zstd, arranca QEMU, falla Parallels |
| v16 libre | 15 abr 00:03 | 2.8 GB | switch a libre.debian.net base |
| v16 slim | 15 abr 07:52 | 2.0 GB | -firefox -docs -locales |
| v16 slim2 | 15 abr 10:26 | 1.2 GB | zstd-22 + fuentes CJK purgadas |
| v16 session-fix | 15 abr 11:27 | 1.2 GB | -light-locker, arreglo XFCE crash |
| v17-final | 15 abr 12:34 | 1.2 GB | correctos wallpapers, panel dock |
| **v18-final** | **15 abr 22:10** | **883 MB** | **entrega final** — login glass, panel pulido, slim agresivo |

---

## 10. SHA-256 de entrega

```
debian-udit-pixelart-arm64-v18-final.iso
67081665e338af82a2991101c0ffacb194a2b1048f2e61990eb531d074a01559
```

---

## 11. Cómo usar el ISO

### En Parallels Desktop (Apple Silicon)
1. Abrir Parallels → **+ New**
2. **Install Windows or another OS from a DVD or image file**
3. Seleccionar `~/Downloads/debian-udit-pixelart-arm64-v18-final.iso`
4. OS type: **Other Linux (ARM64)**
5. Configuración recomendada: 4 CPU, 4 GB RAM
6. Iniciar
7. En el login: usuario `danielsson`, password `root`

### En QEMU
```bash
cd "~/Desktop/os practica"
./scripts/run_qemu.sh debian-udit-pixelart-arm64-v18-final.iso 2048
```

### Verificación del ISO
```bash
shasum -a 256 ~/Downloads/debian-udit-pixelart-arm64-v18-final.iso
# Debe dar: 67081665e338af82a2991101c0ffacb194a2b1048f2e61990eb531d074a01559
```

---

## 12. Lecciones aprendidas

1. **Cubic no sirve para arm64 Apple Silicon.** Genera un `efi.img` de 32 MB fijo que fuerza `Ldsiz=0` en El-Torito. Parallels lo rechaza. Para Parallels necesitas `-isohybrid-apm-hfsplus` y un `efi.img` < 32 MB, que Cubic no puede dar.

2. **`apt autoremove` en chroot es peligroso.** Remueve dependencias "Recommended" de XFCE (como `xfce4-session`) y rompe la sesión. Hay que reinstalar explícitamente después.

3. **`light-locker` se activa por defecto en XFCE Debian** y bloquea la pantalla al login. Si no lo purgas, el usuario ve un password prompt que parece un segundo greeter y se confunde.

4. **Plymouth scripts deben tener archivos embebidos en initramfs.** Un PNG > 1 MB dentro del tema no siempre se embebe bien. Usar JPG comprimido.

5. **Parallels shared folders es la forma correcta** de mover archivos grandes entre Mac y la VM, NO OneDrive ni compartidos simples.

6. **Cada `mksquashfs -comp zstd -Xcompression-level 22`** sobre 4 GB de rootfs en 4 procesadores TCG toma ~10-12 minutos. El nivel 15 toma 4-5 min pero produce un archivo ~20% más grande. El nivel 22 es el máximo y merece la pena para entrega final.

7. **`unsquashfs -s` te dice el formato real** del squashfs (zstd con 1M blocks vs xz con 128K blocks). No asumir — siempre verificar antes de recompactar, porque mezclar formatos causa corrupción silenciosa.

8. **La base ISO de libre.debian.net** (gitlab.com/debdistutils/debian-libre) es la fuente correcta para Debian 13 arm64 live, NO las ISOs oficiales de debian.org (que solo tienen amd64 live).

---

## 13. v19 → v20: ampliación seguridad/robótica (2026-05-19)

### Disparador
El profesor publicó el 2026-04-27 una nueva guía (`NuevaGuia.zip`, "RoboSecOS — Guía de Construcción") que describe un sistema con bloque ofensivo + robótica + menú interactivo whiptail. La guía está pensada para Ubuntu 24.04 + Cubic + usuario `robosec`, pero el profesor confirma que se acepta una **adaptación sobre nuestra base PixelForge** (Debian 13 ARM64) sin rehacer el sistema entero.

### Decisión de alcance
- **Sí:** añadir los paquetes que faltan y los scripts `robomenu` / `robosec-banner.sh` como utilidades adicionales.
- **No:** convertir usuario `danielsson` → `robosec`, no cambiar autologin XFCE → TTY, no tocar branding pixel-art. Eso rompería lo que ya está verificado en Parallels y la memoria entregada.

### Cómo se hizo
1. **Verificación previa de paquetes ya instalados** montando el squashfs de v19 (no fiarse del `filesystem.packages` — incompleto en v19 — sino comprobar binarios reales). Resultado: ~50% de los paquetes de seguridad ya estaban (nmap, wireshark, tshark, tcpdump, fail2ban, openssl, nc, whiptail, xfce4, lightdm, htop, python3, curl, wget). Faltaban ~21.
2. **Limpieza de artefactos viejos** (`work/sq`, `work/rootfs`, `work/bootfix`, `work/inspect*`, `work/sq14`) que ocupaban ~7 GB y eran de las iteraciones v11–v14. Liberó espacio crítico (8.6 GB → 16 GB libres).
3. **Pipeline de build** (`scripts/build_v20.sh`): mount loop ro → rsync árbol → unsquashfs (5 min) → bind mounts (`/dev`, `/proc`, `/sys`, `/run`, `/dev/pts`) → chroot apt-get install → install scripts en `/usr/local/bin/` y `/etc/profile.d/` → regenerar `filesystem.packages` con `dpkg-query` → mksquashfs xz arm (10-15 min) → xorriso con mismo `efi.img` de v19 (3.4 MB → `Ldsiz` válido para Parallels).
4. **Variante de recuperación** (`scripts/build_v20_resume.sh`) para reintentar el chroot sin re-extraer squashfs cuando algo falla mid-pipeline.

### Incidencias resueltas

**Bug 1: apt-get install agrupado aborta en el primer fallo.**
La primera versión del script hacía `apt install -y masscan nikto hydra john hashcat aircrack-ng gobuster whois` en una sola llamada. Como `nikto` no existe en Debian 13 trixie, apt abortó y **ningún** paquete se instaló. Fix: `for pkg in PKGS; apt install -y "$pkg"` con `set +e` para tolerar fallos individuales.

**Bug 2: apt-lists evaporadas entre passes.**
El primer chroot ejecutaba `rm -rf /var/lib/apt/lists/*` al final como limpieza. El segundo pass intentaba instalar sin re-fetch y fallaba con "Unable to locate package" para TODO (incluso paquetes que sí existen). Fix: `apt-get update` al inicio de cada chroot, sí o sí.

**Bug 3: `lolcat` se instala fuera del PATH estándar.**
Debian lo coloca en `/usr/games/lolcat` (convención para *fun tools*). El banner usaba `command -v lolcat` que falla si `/usr/games` no está en PATH. Fix: el banner ahora busca el binario en `/usr/games`, `/usr/bin`, `/usr/local/bin` antes de degradarse a `figlet` plano.

**Bug 4 (CRÍTICO): kernel panic con squashfs xz BCJ-arm.**
El primer v20 ISO generado tenía `mksquashfs -comp xz -Xbcj arm -b 128K` (heredado de `patch_v9_netcat.sh`, era la config de Cubic). Al arrancar en QEMU el kernel arm64 (6.12.63+deb13) tiraba:

```
SQUASHFS error: xz decompression failed, data probably corrupt
SQUASHFS error: Failed to read block 0xf8dda3c: -5
/sbin/init: error while loading shared libraries: libcrypto.so.3: I/O error
Kernel panic - not syncing: Attempted to kill init! exitcode=0x00007f00
```

Lo curioso es que `unsquashfs` desde userland extrae los archivos perfectamente y sus SHA256 son idénticos a los de v19. El problema es que el **filter BCJ-arm de xz está pensado para ARM 32-bit; aplicarlo a binarios ARM64 produce salida que `unsquashfs` puede decodificar (porque tiene tolerancia) pero que el driver de squashfs del kernel rechaza**.

**Fix:** rebuild completo con la misma config que v19 (zstd-22, bloques de 1 MB, sin BCJ). El script v20-fix correcto:
```bash
mksquashfs rootfs filesystem.squashfs \
    -comp zstd -Xcompression-level 22 -b 1M \
    -processors 2 -noappend
```

V19 ya había migrado silenciosamente a zstd-22 (verificado con `unsquashfs -s` sobre `debian-udit-pixelart-arm64-v19-final.iso`) sin que se actualizara el script de patch. El comando original quedó "fosilizado" desde la era Cubic/v9 cuando aún usábamos xz.

### Paquetes que no se incluyeron (documentados como out-of-scope)

| Paquete | Razón |
|---|---|
| `nikto` | No en trixie/main (sí en bookworm 12). Alternativa: `git clone https://github.com/sullo/nikto` post-boot |
| `neofetch` | Eliminado de Debian 13 (upstream archivado 2024). `fastfetch` ya estaba en v19 como reemplazo |
| `metasploit-framework` | Requiere instalador Rapid7 (~2 GB). Snippet documentado en `V20-REPORT.md` §2 |
| `ros-jazzy-ros-base` | Solo binarios oficiales para Ubuntu 24.04. Build desde fuente en Debian: >4h, >5GB |
| `arduino-cli` | Instalable vía script upstream post-boot. ~100 MB de descarga |
| `kicad`, `fritzing` | Demasiado pesados / no en trixie |
| `pigpio`, `micropython` | Específicos Raspberry Pi / redundantes con esptool |

### Total contabilizado
- **19 paquetes nuevos** instalados con éxito (12 vía apt, 7 ya estaban presentes y se confirmaron en pass 2, 1 vía pip)
- **2 scripts nuevos** en `/usr/local/bin/robomenu` y `/etc/profile.d/robosec-banner.sh`
- **0 cambios** en branding, usuarios, autologin, GRUB, tema Plymouth, wallpapers

### Verificación
- ISO final: **1.2 GB** (1175 MB), +186 MB sobre v19
- SHA256: `9f6594e64a928072de1523cb6c6d1e1ae0911c4fbc1c839dd9379a76813c11b2`
- El-Torito `Ldsiz=6848` ✅ (preservado de v19 — Parallels boots OK)
- 1660 paquetes en `filesystem.packages` (vs 778 en v19; +882 incluyendo dependencias automáticas)
- 19 paquetes nuevos directos verificados con `grep` sobre `filesystem.packages`
- Volume ID: `DEBIAN_UDIT_EDITION_V20`
- Hash guardado en `evidencias/v20-sha256.txt`

Ver `V20-REPORT.md` §5-§7 para detalle completo.

---

## 14. Lecciones nuevas

9. **`apt install pkg1 pkg2 pkg3` es transaccional sobre disponibilidad:** si UN paquete no existe, ninguno se instala. Para listas largas con riesgo, usar bucle por paquete con `set +e`.

10. **Las apt-lists son volátiles dentro del live ISO.** Cualquier `apt-get clean` o `rm -rf /var/lib/apt/lists/*` las elimina. Si necesitas instalar más cosas después, `apt-get update` es obligatorio antes.

11. **Debian renombra/elimina paquetes entre releases más de lo que parece.** Casos confirmados en trixie vs bookworm: `neofetch` (eliminado, usar `fastfetch`), `nikto` (eliminado, no hay reemplazo oficial en repos), `fritzing` (eliminado años atrás).

12. **`/usr/games` es PATH legítimo para ejecutables "no serios"** (lolcat, fortune, cowsay). Está incluido en el PATH de Debian por defecto via `/etc/profile`, pero scripts conservadores que setean su propio PATH pueden perderlo.

---

**Fin de la bitácora.**
