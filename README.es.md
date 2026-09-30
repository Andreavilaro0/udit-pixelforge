# UDIT PixelForge — Distribución Linux Personalizada

[English](README.md) · **Español**

**Asignatura:** Sistemas Operativos Avanzados  
**Curso:** 2025–2026  
**Universidad:** UDIT — Universidad de Diseño, Innovación y Tecnología  
**Autores:** Andrea Ávila Romero · Iván Herrera González

---

## Descripción

Este repositorio contiene el trabajo final de la asignatura. El objetivo era construir una distribución Linux live desde cero, personalizada visualmente y con un conjunto de herramientas de diagnóstico, seguridad y recuperación orientadas a administración de sistemas.

El resultado es **UDIT PixelForge**, una ISO basada en Debian 13 Trixie ARM64 que arranca directamente en un entorno gráfico XFCE con autologin, tema Catppuccin Mocha Blue y estética pixel art propia. Incluye un menú interactivo (`robomenu`) accesible desde cualquier terminal.

---

## Contenido del repositorio

| Ruta | Descripción |
|---|---|
| [`MANUAL-PROYECTO.pdf`](MANUAL-PROYECTO.pdf) | Manual técnico completo: proceso de construcción, registro de iteraciones (v8 → v20), errores encontrados y soluciones aplicadas. |
| `scripts/build_v20.sh` | Pipeline reproducible para construir v20 a partir de v19. |
| `scripts/build_v20_resume.sh` | Variante tolerante a fallos para el chroot de instalación. |
| `scripts/build_v20_robomenu_fix.sh` | Rebuild rápido que solo reemplaza el binario robomenu sin tocar paquetes. |
| `scripts/run_qemu.sh` | Script para probar la ISO en QEMU ARM64. |
| `scripts/v20-assets/robomenu` | Menú interactivo principal del sistema (fzf + chafa). |
| `scripts/v20-assets/robosec-banner.sh` | Banner figlet+lolcat que aparece al abrir una TTY. |
| `scripts/v20-assets/icons/` | Cinco iconos pixel art para el menú (seguridad, robótica, red, inicio, apagar). |
| `evidencias/screenshots/` | Capturas de pantalla del sistema en funcionamiento. |
| `evidencias/branding/` | Imágenes del tema visual: wallpapers, Plymouth, login. |
| `evidencias/iso-sha256-*.txt` | Hashes de integridad de cada versión entregada. |

> Los archivos `.iso` **no están incluidos** en el repositorio por su tamaño (entre 883 MB y 1,2 GB). Los hashes SHA-256 de cada versión están en `evidencias/`.

---

## Versión final

| Parámetro | Valor |
|---|---|
| Versión | v20 |
| Tamaño | 1,2 GB |
| Base | Debian 13 Trixie ARM64 (libre.debian.net) |
| Escritorio | XFCE 4.18 · tema Catppuccin Mocha Blue |
| Paquetes instalados | 1660 (dpkg) |
| SHA-256 | `3f8a04a8f1fe6ae5e9962cf555108c669fc7b95f2a28f1aaa97148ef384e612f` |

### Credenciales del sistema live

> Son las credenciales por defecto de la ISO live, pensada como entorno de laboratorio para una asignatura. No son credenciales de ningún sistema real.

| Usuario | Contraseña | Grupos |
|---|---|---|
| `danielsson` | `root` | sudo, wireshark, audio, video, netdev (autologin) |
| `user` | `live` | sudo, wireshark |
| `admin` | `admin` | sudo |
| `root` | `root` | — |

---

## Cómo probar la ISO

### Parallels Desktop (Apple Silicon)

1. Abrir Parallels → **+** → *Install from image file*
2. Seleccionar la ISO `debian-udit-pixelart-arm64-v20-final.iso`
3. Tipo de sistema: **Other Linux (ARM64)**
4. Recursos recomendados: 4 núcleos, 4 GB de RAM
5. Iniciar. El sistema arranca directamente en XFCE sin necesidad de login manual.
6. Para abrir el menú interactivo: abrir una terminal y ejecutar `robomenu`

### QEMU

```bash
./scripts/run_qemu.sh debian-udit-pixelart-arm64-v20-final.iso 2048
```

### Verificar integridad

```bash
echo "3f8a04a8f1fe6ae5e9962cf555108c669fc7b95f2a28f1aaa97148ef384e612f  \
  debian-udit-pixelart-arm64-v20-final.iso" | sha256sum -c
```

---

## Herramientas incluidas

El sistema incorpora herramientas agrupadas por categoría según el enunciado de la práctica:

- **Análisis de red:** nmap, masscan, wireshark, tshark, tcpdump, netcat, arp-scan
- **Seguridad defensiva:** lynis, fail2ban, ufw, chkrootkit, rkhunter, clamav, aide
- **Seguridad ofensiva:** hydra, john, hashcat, aircrack-ng, gobuster, whois
- **Diagnóstico del sistema:** htop, btop, glances, lsof, iotop, strace, fastfetch
- **Gestión de discos:** gparted, smartmontools, testdisk, ddrescue, cryptsetup
- **Recuperación:** chntpw, photorec, safecopy
- **WiFi:** iw, wavemon, wireless-tools, NetworkManager
- **Robótica / hardware:** avrdude, minicom, picocom, screen, esptool (pip)

---

## Proceso de construcción (resumen)

El desarrollo pasó por 20 versiones. Los problemas principales que encontramos fueron:

1. **Cubic no genera ISOs que arranquen en Parallels ARM64.** El `efi.img` que produce Cubic tiene 32 MB, lo que fuerza el campo `Ldsiz` del catálogo El-Torito a `0`. Parallels rechaza silenciosamente cualquier ISO con ese valor. La solución fue cambiar de base a `libre.debian.net` y construir la ISO directamente con `xorriso`, usando el flag `-isohybrid-apm-hfsplus` que Cubic nunca genera.

2. **El squashfs con compresión xz y filtro BCJ-arm produce kernel panic en ARM64.** El driver de squashfs del kernel 6.12 arm64 rechaza bloques generados con ese filtro, aunque `unsquashfs` desde userland los extrae sin problemas. La solución fue recompilar con `zstd` nivel 22 y bloques de 1 MB.

3. **`apt install` sobre una lista de paquetes aborta si uno no existe.** En Debian 13 Trixie no están disponibles `nikto` ni `neofetch`, entre otros. Se resolvió instalando paquete a paquete con un bucle `for` y `set +e` para tolerar fallos individuales.

El detalle completo de cada problema y su solución está en [`MANUAL-PROYECTO.pdf`](MANUAL-PROYECTO.pdf).

---

## Licencia

Material académico. Uso libre para fines educativos con atribución.
