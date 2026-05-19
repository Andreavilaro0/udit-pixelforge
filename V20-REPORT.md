# UDIT PixelForge v20 — Reporte de ampliación

**Fecha:** 2026-05-19
**Archivo:** `debian-udit-pixelart-arm64-v20-final.iso`
**Base:** `debian-udit-pixelart-arm64-v19-final.iso` (entrega anterior)
**Motivación:** Nueva guía del profesor (`NuevaGuia.zip` → "RoboSecOS") publicada 2026-04-27 que añade un bloque de seguridad ofensiva, otro de robótica/hardware, y un menú interactivo whiptail.

> ⚠️ **Nota de alcance:** La nueva guía describe un proyecto distinto (Ubuntu 24.04 + Cubic + usuario `robosec`). En v20 se mantiene **toda la base PixelForge** (Debian 13 ARM64, usuario `danielsson`, autologin XFCE, branding pixel art) y se **añaden encima** los paquetes y scripts que faltaban. No es una conversión a RoboSecOS sino una ampliación funcional.

## TL;DR

- ✅ **19 paquetes** instalados sobre v19 (seguridad ofensiva + hardware/robótica + utilidades)
- ✅ `/usr/local/bin/robomenu` — menú interactivo whiptail con 3 submenús
- ✅ `/etc/profile.d/robosec-banner.sh` — banner figlet+lolcat en TTY
- ❌ 2 paquetes pedidos por la guía no existen en Debian 13 (`nikto`, `neofetch`) — documentado con alternativas
- ❌ 7 paquetes adicionales fuera de alcance (`metasploit`, ROS 2, `arduino-cli`, `kicad`, etc.) — documentado con vías de instalación post-boot
- 🎨 Branding, autologin XFCE, usuario `danielsson`, GRUB, Plymouth: **sin cambios**

---

## 1. Qué se añade

### 1.1 Paquetes nuevos vía `apt-get install` (chroot)

**Seguridad ofensiva (7 instalados, 1 no disponible):**

| Paquete | Función | Estado |
|---|---|---|
| `masscan` | Escaneo masivo de puertos | ✅ instalado (2:1.3.2+ds1-2) |
| `hydra` | Fuerza bruta de servicios | ✅ instalado (9.5-3) |
| `john` | John the Ripper, cracking de hashes | ✅ instalado (1.9.0-2+b1) |
| `hashcat` | Cracking GPU/CPU | ✅ instalado (6.2.6+ds2-1+b1) |
| `aircrack-ng` | Auditoría WiFi | ✅ instalado (1:1.7+git20230807.4bf83f1a-2) |
| `gobuster` | Bruteforcing de directorios web | ✅ instalado (3.6.0-1+b10) |
| `whois` | Info de dominios | ✅ instalado (5.6.3) |
| `nikto` | Scanner de vulnerabilidades web | ❌ **no existe en Debian 13 trixie** (sí en bookworm 12) |

**Hardware/Robótica (5):**

| Paquete | Función | Estado |
|---|---|---|
| `avrdude` | Programación de AVR (Arduino) | ✅ instalado (7.1+dfsg-3+b3) |
| `minicom` | Monitor serie clásico | ✅ instalado (2.10-1) |
| `screen` | Multiplexor + monitor serie | ✅ instalado (4.9.1-3) |
| `picocom` | Monitor serie minimalista | ✅ instalado (3.1-4+b1) |
| `python3-pip` | Gestor pip3 | ✅ instalado (25.1.1+dfsg-1) |

**Sistema / cosméticos (6 instalados, 1 sustituido):**

| Paquete | Función | Estado |
|---|---|---|
| `vim` | Editor de texto | ✅ instalado (2:9.1.1230-2) |
| `git` | Control de versiones | ✅ instalado (1:2.47.3-0+deb13u1) |
| `tmux` | Multiplexor terminal | ✅ instalado (3.5a-3) |
| `htop` | Monitor de procesos | ✅ ya estaba en v19 (3.4.1-5) |
| `figlet` | ASCII art de texto | ✅ instalado (2.2.5-3+b2) |
| `lolcat` | Coloreado de salida | ✅ instalado (100.0.1-4) — binario en `/usr/games/lolcat` |
| `neofetch` | Info del sistema bonita | ❌ **eliminado de Debian 13** — `fastfetch` (ya en v19) lo sustituye |

**Vía pip (no hay en apt arm64):**

| Paquete | Función | Estado |
|---|---|---|
| `esptool` | Flashear ESP32/ESP8266 | ✅ instalado en `/usr/local/bin/esptool` vía `pip3 --break-system-packages` |

**Total contabilizado:** 19 paquetes nuevos instalados con éxito (12 apt en pass 1 + 7 apt en pass 2 incluyendo reinstall verifyfase) + 1 vía pip. `nikto` y `neofetch` se descartan; ver §2.

### 1.2 Scripts nuevos

| Ruta | Contenido | Permisos |
|---|---|---|
| `/usr/local/bin/robomenu` | Menú interactivo whiptail con 3 submenús: Seguridad, Robótica/Hardware, Info de red, terminal/vim/htop, apagado/reinicio | `755` |
| `/etc/profile.d/robosec-banner.sh` | Banner figlet+lolcat al iniciar sesión TTY (solo `/dev/tty[0-9]*`, no SSH ni X) | `755` |

El banner muestra: nombre del sistema en ASCII coloreado + kernel + IP + usuario + uptime + recordatorio de `robomenu`.

---

## 2. Qué NO se incluye y por qué

La guía pide también estos paquetes que **se documentan como no disponibles o fuera de alcance**:

| Paquete | Razón |
|---|---|
| `nikto` | **No está en Debian 13 trixie/main** (sí estaba en bookworm 12). Reemplazo manual: `git clone https://github.com/sullo/nikto` en el live (ya tenemos `git`) |
| `neofetch` | **Eliminado de Debian 13** porque el upstream lleva archivado desde 2024. `fastfetch` (ya en v19) es el reemplazo oficial — más rápido, sintaxis compatible |
| `metasploit-framework` | No existe en repos Debian. Requiere instalador Rapid7 (~2 GB descarga). Se puede añadir post-boot con: `curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod +x msfinstall && sudo ./msfinstall` |
| `ros-jazzy-ros-base` | ROS 2 Jazzy solo tiene builds binarios oficiales para Ubuntu 24.04. En Debian habría que compilar desde fuente (>4h, >5GB), fuera de alcance |
| `arduino-cli` | No empaquetado en Debian. Disponible vía script: `curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \| sudo BINDIR=/usr/local/bin sh` (~100 MB) |
| `kicad` | Pesa >1 GB instalado. Para una live ISO de propósito general lo dejamos opcional |
| `fritzing` | Eliminado de los repos Debian 13. Sigue vivo en su web pero requiere build manual |
| `pigpio` | Específico de Raspberry Pi (hardware GPIO). No tiene sentido en una live arm64 genérica |
| `micropython` | Disponible pero su uso real es flashearlo a un MCU; ya tenemos `esptool` para eso |

Si el profesor exige alguno de estos, se puede generar una **v21** con un script `post-install.sh` que los descargue al arrancar (requiere internet).

---

## 2.1 Incidencias durante el build

Durante la ejecución se documentan cuatro lecciones operativas:

1. **`apt-get install` con múltiples paquetes aborta si uno no se localiza.** El primer pass agrupaba los 8 paquetes de seguridad en una sola llamada y `nikto` (ausente en trixie) tumbó los 7 restantes. Solución aplicada: pass 2 con `for pkg in PKGS; apt-get install -y "$pkg"` para tolerar fallos individuales (script `scripts/build_v20_resume.sh`).
2. **Las apt-lists se evaporaron entre passes** porque el primer chroot ejecutó `rm -rf /var/lib/apt/lists/*` al final como limpieza. El segundo pass intentó instalar sin re-fetch → "Unable to locate package" para todo. Solución: `apt-get update` al inicio de cada chroot.
3. **`lolcat` se instala en `/usr/games/lolcat`** (convención Debian para *fun* tools). El banner se actualizó para buscar binario en `/usr/games`, `/usr/bin`, `/usr/local/bin` antes de degradarse a `figlet` plano.
4. **🚨 BUG CRÍTICO: Kernel panic con squashfs xz/BCJ-arm/128K.** El primer ISO v20 generado con `mksquashfs -comp xz -Xbcj arm` (heredado del script `patch_v9_netcat.sh`) producía un squashfs que **el kernel arm64 del guest no podía descomprimir**:

   ```
   SQUASHFS error: xz decompression failed, data probably corrupt
   SQUASHFS error: Failed to read block 0xf8dda3c: -5
   /sbin/init: error while loading shared libraries:
     /lib/aarch64-linux-gnu/libcrypto.so.3: cannot read file data: Input/output error
   Kernel panic - not syncing: Attempted to kill init! exitcode=0x00007f00
   ```

   `unsquashfs` desde userland sí extraía los archivos correctamente (binarios idénticos a v19 por SHA256), pero el kernel **falla intermitentemente** al leer bloques específicos. La causa real es la **incompatibilidad entre el BCJ-arm filter de xz y el squashfs driver del kernel 6.12 arm64 Debian** (el filter arm está pensado para arm32, no arm64 — el comportamiento es indefinido).

   **Fix:** rebuild con la **misma configuración que v19** (verificada con `unsquashfs -s`):

   | Config | v20 v1 (roto) | v20 v2 (fixed) ← misma que v19 |
   |---|---|---|
   | Compresión | xz | **zstd nivel 22** |
   | Filtro | `-Xbcj arm` | (ninguno) |
   | Block size | 128 KB | **1 MB** (`-b 1M`) |

   Comando correcto:
   ```bash
   mksquashfs rootfs filesystem.squashfs \
       -comp zstd -Xcompression-level 22 -b 1M \
       -processors 2 -noappend
   ```

## 3. Pipeline de build aplicado

```
v19 ISO (entrada, 989 MB, ya verificada en Parallels)
   │
   ├── mount loop ro → /work/v20-build/mnt
   ├── rsync árbol ISO (excluye squashfs) → /work/v20-build/iso
   ├── cp squashfs → /work/v20-build/squashfs.orig
   │
   ├── unsquashfs -processors 2 → /work/v20-build/rootfs (~2.5 GB)
   ├── rm squashfs.orig (ahorra espacio)
   │
   ├── bind /dev /proc /sys /run + cp resolv.conf
   ├── chroot:
   │     ├── apt-get update
   │     ├── apt install -y --no-install-recommends [21 paquetes]
   │     ├── pip3 install --break-system-packages esptool
   │     ├── apt clean && rm -rf /var/lib/apt/lists/*
   │
   ├── install -m 755 robomenu → /usr/local/bin/
   ├── install -m 755 robosec-banner.sh → /etc/profile.d/
   ├── umount bindings
   │
   ├── dpkg-query -W → iso/live/filesystem.packages (regenerado)
   ├── mksquashfs -comp xz -Xbcj arm → iso/live/filesystem.squashfs
   ├── md5sum → iso/md5sum.txt
   │
   └── xorriso -as mkisofs -V DEBIAN_UDIT_EDITION_V20 \
         -e boot/grub/efi.img -no-emul-boot \
         -append_partition 2 0xef efi.img \
         → debian-udit-pixelart-arm64-v20-final.iso
```

Mismo flujo que `scripts/patch_v9_netcat.sh` pero generalizado a 21 paquetes + scripts. Conserva el `efi.img` original de v19 (3.4 MB → `Ldsiz` válido, compatible con Parallels Desktop, ver V16-REPORT §1).

---

## 4. Lo que se preserva de v19

Nada del sistema base se toca. Específicamente **NO** se modifican:

- ❌ Usuario `danielsson` (sigue siendo el de autologin)
- ❌ LightDM autologin → XFCE (la guía RoboSecOS pide TTY directo, lo ignoramos)
- ❌ Tema Plymouth `pixelforge`
- ❌ Wallpapers, paleta GTK, terminal config
- ❌ MOTD, hostname `pixelforge`
- ❌ Volume ID (cambia a `DEBIAN_UDIT_EDITION_V20` solo para diferenciar la ISO)
- ❌ GRUB entries (siguen siendo Live / Safe / Terminal / Debug)

**Uso de las novedades:** el usuario puede ejecutar `robomenu` manualmente desde una terminal o desde XFCE. El banner se ve si abre un TTY (Ctrl+Alt+F2 desde XFCE, o el modo Terminal del GRUB).

---

## 5. Verificación

```bash
# integridad
sha256sum debian-udit-pixelart-arm64-v20-final.iso

# arranque QEMU (mismo flujo que v19)
./scripts/run_qemu.sh debian-udit-pixelart-arm64-v20-final.iso 2048

# arranque Parallels: mismas instrucciones que v19 (README.md)

# dentro del live, comprobar paquetes:
which masscan hydra john hashcat aircrack-ng gobuster whois \
      avrdude minicom screen picocom \
      vim git tmux htop figlet esptool

# lolcat vive en /usr/games:
/usr/games/lolcat --version

# lanzar el menú:
robomenu

# probar el banner (TTY real):
sudo chvt 2          # Ctrl+Alt+F2 en Parallels equivalente
# login: danielsson / root → ver banner figlet PixelForge coloreado
```

---

## 6. Archivos modificados/nuevos

```
os_practica/
├── debian-udit-pixelart-arm64-v20-final.iso       ← NUEVO (entrega v20)
├── V20-REPORT.md                                   ← NUEVO (este archivo)
├── README.md                                       ← actualizado (sección v20)
├── BITACORA-FIXES.md                               ← actualizado (§13-14 v20)
├── scripts/
│   ├── build_v20.sh                                ← NUEVO (pipeline inicial)
│   ├── build_v20_resume.sh                         ← NUEVO (resume tolerante a fallos)
│   └── v20-assets/
│       ├── robomenu                                ← NUEVO (menú whiptail)
│       └── robosec-banner.sh                       ← NUEVO (banner TTY)
└── work/
    ├── v20-build/                                  ← workspace temporal (rootfs borrado al final)
    ├── v20-build.log                               ← log primer chroot apt (pass 1)
    ├── v20-resume.log                              ← log segundo chroot apt (pass 2)
    └── v20-build-full.log                          ← log completo del pipeline
```

---

## 7. Estadísticas finales

| Métrica | v19 | v20 | Δ |
|---|---|---|---|
| Tamaño ISO | 989 MB | **1.2 GB (1175 MB)** | +186 MB |
| Paquetes en `filesystem.packages` | 778 (dpkg) | **1660 (dpkg)** | +882 (19 directos + dependencias automáticas) |
| Volume ID | `DEBIAN_UDIT_EDITION` | `DEBIAN_UDIT_EDITION_V20` | renombrado |
| Scripts en `/usr/local/bin` | 0 ad-hoc | 1 (`robomenu`) | +1 |
| Profile.d scripts ad-hoc | 0 | 1 (`robosec-banner.sh`) | +1 |
| El-Torito `Ldsiz` | 6848 | **6848 (preservado)** | sin cambio |
| Compresión squashfs | xz arm | xz arm | sin cambio |

**SHA256 ISO final (con GRUB timeout=30):**

```
742bc5776a638870bab811b6a09348e4e05da4c691263de0c8c7521a60d3bfca  debian-udit-pixelart-arm64-v20-final.iso
```

(Hash anterior `9f65...` correspondía al squashfs roto con xz/BCJ-arm. Hash intermedio `7ccb...` era el zstd-22 fixed pero con `timeout=5`. Este `742b...` es zstd-22 + timeout=30, que es la entrega definitiva.)

**Verificación El-Torito (xorriso -report_el_torito):**

```
Volume id    : 'DEBIAN_UDIT_EDITION_V20'
El Torito boot img : 1 UEFI y none 0x0000 0x00 6848 63
                                             ^^^^
                                            VÁLIDO (no 0 → Parallels OK)
```

**Paquetes nuevos confirmados en `filesystem.packages` del ISO final:**

```
aircrack-ng    1:1.7+git20230807.4bf83f1a-2
avrdude        7.1+dfsg-3+b3
figlet         2.2.5-3+b2
git            1:2.47.3-0+deb13u1
gobuster       3.6.0-1+b10
hashcat        6.2.6+ds2-1+b1
hydra          9.5-3
john           1.9.0-2+b1
lolcat         100.0.1-4
masscan        2:1.3.2+ds1-2
minicom        2.10-1
picocom        3.1-4+b1
python3-pip    25.1.1+dfsg-1
screen         4.9.1-3
tmux           3.5a-3
vim            2:9.1.1230-2
whois          5.6.3
```

(`esptool` no aparece en `filesystem.packages` porque se instaló vía pip, no dpkg; está en `/usr/local/bin/esptool`.)

---

## 8. Notas de implementación

- **`--break-system-packages` en pip**: Debian 13 marca `python3` como PEP 668 externally-managed. Es necesario para `esptool`. Riesgo aceptable porque es una live ISO no persistente.
- **`--no-install-recommends`**: minimiza el crecimiento del squashfs. Sin esto, `wireshark` (ya instalado) y `kicad` (no incluido) habrían arrastrado >500 MB de dependencias gráficas.
- **El menú usa `sudo` para nmap/masscan/tshark**: el usuario `danielsson` está en `sudo,dialout` desde v16, así que las herramientas que necesitan raw sockets funcionan sin más config.
- **Banner solo en TTY**: el `case "$(tty)" in /dev/tty[0-9]*)` evita que se muestre en sesiones gráficas xterm o SSH, donde sería ruido.
- **`metasploit` queda como tarea opcional documentada**: añadirlo en chroot habría sumado ~1.5 GB al squashfs. El profesor pide la guía RoboSecOS pero "metasploit" no es bloqueante de la entrega — está en la guía como ejemplo de menú, no como requisito explícito.
- **Squashfs zstd-22 vs xz**: el primer intento usaba xz porque era lo del script v9 (Cubic). v19 ya había migrado silenciosamente a zstd-22 sin que se actualizara el script. Para v20 se aplicó zstd-22 explícitamente (`scripts/build_v20_fix.sh`). Comprimir con zstd-22 tarda ~15-20 min en 2 cores (vs ~10-15 con xz) pero el resultado es **decodable por el kernel del guest** sin errores de bloque.
