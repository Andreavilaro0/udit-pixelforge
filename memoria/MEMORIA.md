---
title: "UDIT PixelForge — Memoria Técnica del Proyecto Final"
subtitle: "Construcción de una Distribución Linux Personalizada sobre Debian 13 (trixie) ARM64"
author: "Andrea & Iván"
institution: "UDIT — Universidad de Diseño, Innovación y Tecnología"
course: "Sistemas Operativos Avanzados"
date: "Abril 2026"
version: "v19 — ISO final · Documento 2.0"
lang: es
geometry: "a4paper, margin=2.3cm"
fontsize: 11pt
toc: true
toc-depth: 3
numbersections: true
header-includes:
  - \usepackage{longtable}
  - \usepackage{booktabs}
---

\newpage

# Portada

**Título del Proyecto:** UDIT PixelForge — Distribución Linux personalizada para diagnóstico técnico, análisis defensivo y recuperación de sistemas.

**Base técnica:** Debian GNU/Linux 13.3 (*trixie*) · Arquitectura ARM64 (aarch64).

**Métodos de construcción:** Cubic (v1–v14) y reconstrucción manual sobre base libre.debian.net (v15–v19).

**Autores:** Andrea & Iván.

**Asignatura:** Sistemas Operativos Avanzados.

**Centro:** UDIT — Universidad de Diseño, Innovación y Tecnología.

**Fecha de entrega:** Abril 2026.

**Versión de la ISO documentada:** `debian-udit-pixelart-arm64-v19-final.iso`

- Tamaño: 989 MB
- SHA-256: `57bbc10bd5626aa3f7d2f3379da6cbb5b9e32964dd4e058d07bb9df43c6b33c3`
- Volume ID: `UDIT_PIXELFORGE`
- Hostname del sistema live: `pixelforge`
- Kernel: `6.12.63+deb13-arm64`
- Paquetes instalados: 1564
- Compresión squashfs: zstd nivel 22, bloques de 1 MB

\newpage

# Introducción

El presente documento constituye la memoria técnica completa del proyecto **UDIT PixelForge**, una distribución GNU/Linux personalizada desarrollada como trabajo final de la asignatura Sistemas Operativos Avanzados de la UDIT. El documento recoge el diseño, la construcción, la verificación y la justificación técnica de todos los componentes del sistema, desde la selección de la base hasta la validación en múltiples hipervisores.

El objetivo del proyecto no es producir una distribución de uso generalista, sino entregar un sistema *live* ligero, reproducible y exhaustivamente documentado, que funcione como **kit de campo técnico** para tareas de diagnóstico de red, análisis del sistema, auditoría defensiva, gestión de discos, recuperación de datos y conectividad WiFi. La distribución se concibe como una herramienta profesional de diagnóstico que un técnico puede llevar en un USB y arrancar en cualquier equipo ARM64 compatible con UEFI, sin necesidad de instalación previa.

La ruta de construcción se fundamenta sobre tres pilares decididos desde el primer día:

1. **Debian como base** — por estabilidad, tamaño de repositorios oficiales, ausencia de telemetría, soporte nativo ARM64 y licencia libre.
2. **Iteración continua** — 19 versiones de la ISO, comenzando con Cubic como herramienta automatizada y migrando a una reconstrucción manual cuando los límites de Cubic se hicieron evidentes en el entorno de virtualización ARM64.
3. **Identidad visual profesional** — tema Catppuccin Mocha con iconografía Papirus-Dark, wallpapers de producción propia y Plymouth con arte pixel personalizado, conformando una experiencia visual coherente y reconocible.

La ISO final es la **v19**, producto de diecinueve ciclos de iteración documentados, lo que implica que el flujo de construcción se ha probado, corregido y optimizado repetidamente hasta obtener un artefacto arrancable, verificado en Parallels Desktop (Apple Silicon) y QEMU aarch64, con XFCE autologueado y todas las herramientas del enunciado operativas.

\newpage

# Objetivos

## Objetivo general

Diseñar, construir y documentar una distribución GNU/Linux basada en Debian 13, optimizada en consumo de recursos, arrancable en modo Live desde USB, orientada a tareas técnicas y de análisis, con una identidad visual profesional coherente, y con todo el proceso registrado en una memoria universitaria reproducible.

## Objetivos específicos

1. Cumplir de forma verificable cada requisito del enunciado publicado por la asignatura.
2. Producir una imagen ISO funcional, firmable por hash, lista para escribir en un USB o arrancar en una máquina virtual ARM64.
3. Incluir el conjunto completo de herramientas especificadas en el enunciado, clasificadas por categoría técnica, sin software superfluo.
4. Aplicar una estrategia de optimización explícita: qué se mantiene, qué se elimina, qué se sustituye por alternativas más ligeras, y por qué.
5. Aplicar un *branding* completo: wallpapers de producción propia, tema Catppuccin Mocha, Plymouth con arte pixel, LightDM personalizado, MOTD ASCII y panel XFCE configurado como dock de herramientas.
6. Documentar cada fase con comandos exactos, resultado esperado, resultado observado y verificación.
7. Validar la ISO en al menos dos hipervisores ARM64 distintos (Parallels Desktop y QEMU).
8. Dejar la memoria lista para exportar a PDF con Pandoc sin pasos manuales adicionales.

\newpage

# Requisitos del Enunciado

El enunciado oficial de evaluación exige el cumplimiento de los siguientes requisitos. La tabla mapea cada uno con su verificación concreta en UDIT PixelForge v19.

| # | Requisito | Verificación en PixelForge v19 |
|---|---|---|
| R1 | Ligera en consumo de recursos | XFCE 4.18, 1564 paquetes, 989 MB ISO, idle < 500 MB RAM |
| R2 | Funcional en hardware limitado | Arranca en 2 CPU / 512 MB RAM (texto) o 1 GB (XFCE) |
| R3 | Portable (USB) o instalable | Live Debian estándar, escribible en USB con `dd` |
| R4 | Orientada a tareas técnicas y de análisis | Suite completa de 22+ herramientas documentada en la sección 9 |
| R5 | Base Debian, Ubuntu Minimal o Arch | Debian 13.3 *trixie* (arm64) |
| R6 | Interfaz gráfica ligera | XFCE 4.18 con panel superior y dock inferior |
| R7 | Arranque estable | GRUB EFI con 4 entradas, kernel oficial Debian |
| R8 | Nombre de la distribución | **UDIT PixelForge** (hostname: `pixelforge`, Volume ID: `UDIT_PIXELFORGE`) |
| R9 | Objetivo principal documentado | Secciones 2 y 3 |
| R10 | Perfil de usuario | Sección 7 |
| R11 | Justificación de la base | Sección 5 |
| R12 | Estrategia de optimización | Sección 15 |
| R13 | Consumo estimado de recursos | Sección 18 |
| R14 | Herramientas reales, no colecciones redundantes | Secciones 9 y 10 |
| R15 | Persistencia opcional | Documentada en sección 15 |
| R16 | Entorno limpio | Sección 15 |
| R17 | Documentación técnica | Este documento |

\newpage

# Justificación de Debian como Base

Frente a las tres opciones del enunciado (Debian, Ubuntu Minimal, Arch), se eligió **Debian** por los siguientes motivos, cada uno defendible de forma independiente:

1. **Estabilidad.** Debian congela versiones de paquetes durante ciclos largos y solo aplica parches de seguridad en las ramas stable y testing. Esto reduce el riesgo de que una herramienta crítica cambie su interfaz de línea de comandos entre iteraciones del proyecto.

2. **Tamaño del repositorio.** Todas las herramientas del enunciado — Wireshark, Nmap, netcat-openbsd, tcpdump, btop, Glances, lsof, iotop, GParted, smartmontools, Lynis, Fail2Ban, UFW, chkrootkit, chntpw, TestDisk, iw, wavemon — están disponibles en los repositorios oficiales sin necesidad de añadir PPAs externos ni repositorios de terceros, lo que mantiene la trazabilidad y la reproducibilidad.

3. **Ausencia de telemetría.** A diferencia de Ubuntu, que incluye `ubuntu-report`, `popularity-contest` y servicios como Livepatch por defecto, Debian no envía datos de uso. Para una distribución orientada a auditoría y diagnóstico defensivo, esta propiedad es coherente y deseable.

4. **Compatibilidad con las herramientas de construcción.** Debian es compatible tanto con Cubic (que detecta el layout `live/filesystem.squashfs`) como con la reconstrucción manual mediante `xorriso` y `mksquashfs`. Ambos métodos se emplearon durante el desarrollo del proyecto.

5. **Soporte nativo ARM64.** El equipo de desarrollo utiliza un host ARM64 (Parallels sobre Apple Silicon). Construir una ISO ARM64 es directo sobre una base ARM64 oficial de Debian, sin necesidad de emulación cruzada.

6. **Licencia libre.** Debian distribuye únicamente software libre en su rama `main`. La ISO base utilizada procede de libre.debian.net, lo que refuerza el compromiso con el software libre y facilita la reproducibilidad del proyecto.

Se descartaron las alternativas con criterio fundamentado:

- **Ubuntu Minimal**: añadiría snap, telemetría y una capa de branding de Canonical innecesaria para el propósito del proyecto.
- **Arch Linux**: el proyecto necesita un artefacto ISO cerrado y reproducible. Arch prioriza el modelo *rolling release* sobre imágenes live preempaquetadas, lo que encaja peor en un flujo de construcción ISO orientado a la entrega.

\newpage

# Nombre y Concepto de la Distro

**Nombre:** UDIT PixelForge.

**Origen del nombre:**

- *UDIT* reconoce a la institución académica y establece el vínculo con la asignatura.
- *PixelForge* combina la estética pixel art del proyecto con la metáfora de *forja*: la ISO se forja iterativamente a partir de una base Debian, añadiendo herramientas y puliendo la experiencia hasta obtener un producto acabado.
- Hostname interno: `pixelforge` (reflejado en `/etc/hostname`).
- Volume ID ISO 9660: `UDIT_PIXELFORGE` (para reconocimiento por GRUB vía `search --label`).

**Concepto visual:** profesional-técnico con acabado Catppuccin Mocha y acentos pixel art. La dirección visual busca un equilibrio entre la estética moderna del tema Catppuccin (paleta cálida sobre fondo oscuro, bordes suaves) y elementos pixel art en Plymouth y MOTD que dan personalidad sin comprometer la legibilidad. No se trata de una estética infantil, sino de un guiño a la cultura técnica retro con ejecución contemporánea.

**Paleta principal (Catppuccin Mocha):**

| Rol | Valor | Uso |
|---|---|---|
| Base | `#1e1e2e` | Fondo de escritorio y terminales |
| Surface | `#313244` | Paneles y superficies secundarias |
| Blue | `#89b4fa` | Acento primario, selección, enlaces |
| Text | `#cdd6f4` | Texto principal |
| Overlay | `#6c7086` | Texto secundario, bordes |

\newpage

# Perfil de Usuario

UDIT PixelForge está pensada para cuatro perfiles de usuario reales:

1. **Estudiante técnico-universitario** que necesita un laboratorio live rápido de desplegar en cualquier máquina del aula, sin tocar el disco del equipo. Puede arrancar desde USB, ejecutar prácticas de red con Wireshark o Nmap, y apagar sin dejar rastro.

2. **Técnico de soporte de campo** que llega a un equipo sin sistema operativo utilizable y necesita herramientas de diagnóstico (btop, Glances, iotop), recuperación de datos (TestDisk, PhotoRec), gestión de particiones (GParted) y rearmado de contraseñas Windows (chntpw), todo sin instalar nada.

3. **Analista defensivo** que audita un host o una red local en modo read-only con Lynis para auditoría del sistema, chkrootkit para detección de rootkits, Wireshark y tcpdump para inspección de tráfico, y Fail2Ban y UFW para protección activa.

4. **Formador** que desea enseñar administración Linux con una imagen reproducible, estable, con identidad visual reconocible en pantalla y herramientas profesionales preinstaladas.

PixelForge **no** es una distribución de pentesting ofensivo. No incluye Metasploit, Burp Suite, Aircrack-ng en modo ataque ni exploits. El enunciado del proyecto especifica explícitamente un enfoque profesional y defensivo en la categoría de seguridad, y PixelForge respeta esa frontera.

\newpage

# Arquitectura y Diseño del Sistema

## Pila de software

```
┌──────────────────────────────────────────────────────┐
│  Aplicaciones técnicas (Wireshark, Nmap, btop, …)    │
├──────────────────────────────────────────────────────┤
│  Escritorio XFCE 4.18 (xfce4-session, xfwm4,        │
│  xfdesktop4, xfce4-panel)                            │
├──────────────────────────────────────────────────────┤
│  LightDM + lightdm-gtk-greeter (autologin)           │
├──────────────────────────────────────────────────────┤
│  systemd + NetworkManager                            │
├──────────────────────────────────────────────────────┤
│  Userland Debian 13.3 trixie (1564 paquetes)         │
├──────────────────────────────────────────────────────┤
│  Kernel Linux 6.12.63+deb13-arm64 + live-boot        │
├──────────────────────────────────────────────────────┤
│  GRUB EFI (arm64) — 4 entradas de menú               │
├──────────────────────────────────────────────────────┤
│  Firmware UEFI                                       │
└──────────────────────────────────────────────────────┘
```

## Layout de la ISO

```
debian-udit-pixelart-arm64-v19-final.iso  (989 MB)
├── EFI/BOOT/
│   └── BOOTAA64.EFI          ← loader EFI ARM64
├── boot/
│   ├── grub/
│   │   ├── grub.cfg           ← menú con 4 entradas
│   │   ├── efi.img            ← imagen EFI embebida (3.4 MB, de libre.debian.net)
│   │   └── themes/            ← tema visual GRUB
│   └── boot.catalog
└── live/
    ├── vmlinuz                ← kernel ARM64
    ├── initrd.img             ← initramfs
    └── filesystem.squashfs    ← sistema comprimido (zstd lvl 22, 1 MB block)
```

## Flujo de arranque

1. El firmware UEFI del equipo o hipervisor carga `EFI/BOOT/BOOTAA64.EFI`.
2. GRUB presenta el menú con cuatro entradas (timeout configurable).
3. El usuario selecciona una entrada o se carga la predeterminada (PixelForge Live gráfico).
4. El kernel y el initramfs se cargan desde `/live/`. Parámetros del kernel: `boot=live components locales=es_ES.UTF-8 keyboard-layouts=es quiet splash`.
5. `live-boot` monta el squashfs como raíz mediante overlayfs.
6. Plymouth reproduce el tema `pixelforge` durante la carga (portal pixel art 3640x2048).
7. systemd levanta NetworkManager y LightDM.
8. LightDM aplica autologin del usuario `danielsson` y abre la sesión XFCE.
9. Escritorio listo con wallpaper `wallpaper.png` (edificio UDIT Gemini, 2560x1440).
10. Fastfetch se ejecuta automáticamente al abrir una terminal, mostrando información del sistema.

## Menú GRUB (4 entradas)

| Entrada | Descripción | Parámetros especiales |
|---|---|---|
| PixelForge Live | Arranque gráfico predeterminado | `quiet splash` |
| PixelForge Live (modo seguro) | Arranque sin aceleración gráfica | `nomodeset` |
| PixelForge Terminal | Arranque en modo texto | `systemd.unit=multi-user.target` |
| PixelForge Debug | Arranque con logs verbosos | Sin `quiet`, sin `splash` |

\newpage

# Herramientas Incluidas y Justificación

Todas las herramientas obligatorias del enunciado están instaladas y verificadas en la ISO v19. Se organizan por categoría funcional.

## Análisis de red

| Paquete | Descripción | Justificación |
|---|---|---|
| `wireshark` | Inspección profunda de paquetes con GUI (+ `tshark` CLI) | Herramienta de referencia para análisis de protocolos. Incluye tanto la interfaz gráfica como el analizador de línea de comandos `tshark`. |
| `nmap` | Descubrimiento de red y auditoría de puertos | Estándar de la industria para escaneo de redes. Proporciona además `ncat` como alternativa a netcat. |
| `netcat-openbsd` | Transferencia de datos y depuración de conexiones TCP/UDP | Variante OpenBSD de netcat, ligera y segura, requerida por el enunciado. |
| `tcpdump` | Captura de paquetes en línea de comandos | Indispensable para diagnóstico de red en modo texto, sin necesidad de entorno gráfico. |

## Diagnóstico del sistema

| Paquete | Descripción | Justificación |
|---|---|---|
| `btop` | Monitor de procesos, CPU, memoria, disco y red | Sustituto moderno de `htop` con interfaz TUI avanzada y menor consumo. El enunciado acepta `htop` o `btop`. |
| `glances` | Monitor de sistema integral con salida estructurada | Complementa a btop con exportación a JSON, CSV y API web. Observabilidad integral del sistema. |
| `lsof` | Listado de archivos abiertos por proceso | Herramienta fundamental para auditoría de procesos y detección de fugas de descriptores. |
| `iotop` | Monitor de uso de disco por proceso | Permite identificar qué procesos generan carga de E/S, crítico para diagnóstico de rendimiento. |

## Gestión de discos

| Paquete | Descripción | Justificación |
|---|---|---|
| `gparted` | Particionado gráfico de discos | Interfaz intuitiva para redimensionar, crear y eliminar particiones. |
| `util-linux` | Utilidades de administración (`lsblk`, `fdisk`) | Suite estándar de Linux para gestión de dispositivos de bloque y particiones desde CLI. |
| `smartmontools` | Monitorización SMART de discos HDD/SSD | Permite evaluar la salud del disco y predecir fallos mediante `smartctl`. |

## Seguridad y auditoría (defensiva)

| Paquete | Descripción | Justificación |
|---|---|---|
| `lynis` | Auditoría integral de seguridad del sistema | Analiza configuración, permisos, servicios y vulnerabilidades conocidas. Genera informe con puntuación. |
| `fail2ban` | Protección contra fuerza bruta en servicios de red | Bloquea IPs que intentan acceso repetido fallido a SSH y otros servicios. |
| `ufw` | Cortafuegos simplificado (frontend de iptables/nftables) | Permite configurar reglas de firewall con sintaxis legible, adecuado para usuarios intermedios. |
| `chkrootkit` | Detección de rootkits en el sistema | Inspecciona binarios del sistema en busca de firmas de rootkits conocidos. El enunciado acepta `chkrootkit` o `rkhunter`. |

## Recuperación y acceso

| Paquete | Descripción | Justificación |
|---|---|---|
| `chntpw` | Reseteo de contraseñas Windows offline | Permite acceder a un sistema Windows bloqueado editando el SAM sin necesidad de la contraseña original. |
| `testdisk` | Recuperación de particiones y archivos | El paquete incluye tanto TestDisk (recuperación de particiones) como PhotoRec (recuperación de archivos borrados por firma). |

## Conectividad WiFi

| Paquete | Descripción | Justificación |
|---|---|---|
| `iw` | Información de interfaz WiFi a nivel kernel | Herramienta moderna para configuración y diagnóstico de interfaces inalámbricas. |
| `network-manager` (`nmcli`) | Gestión de conexiones de red | Proporciona `nmcli` para gestión completa de perfiles de red WiFi, Ethernet y VPN desde CLI. |
| `wavemon` | Monitor de señal WiFi en TUI | Visualización en tiempo real de la calidad de la señal, ruido y parámetros de la conexión inalámbrica. |

\newpage

# Herramientas Descartadas y Por Qué

| Paquete / Tecnología | Razón de descarte |
|---|---|
| `htop` | Redundante con `btop`. El enunciado acepta cualquiera de los dos. `btop` ofrece una interfaz más completa con gráficos de red y disco integrados. |
| `rkhunter` | Redundante con `chkrootkit`. El enunciado acepta cualquiera. `chkrootkit` tiene menor huella y dependencias. |
| `aircrack-ng` | Fuera del alcance: el enunciado exige enfoque defensivo, no ofensivo. |
| `metasploit-framework` | Herramienta ofensiva de explotación, contradice el perfil defensivo del proyecto. |
| `burpsuite` | Herramienta ofensiva de análisis de aplicaciones web, fuera del alcance. |
| `libreoffice` | Fuera del propósito técnico de la distribución. Inflaría la ISO significativamente sin aportar valor al perfil de usuario objetivo. |
| `firefox-esr` | No requerido por el enunciado. Se priorizó mantener la ISO por debajo de 1 GB. |
| `snap` / `snapd` | Incompatible con la filosofía Debian pura. Añade overhead de runtime (snapd daemon) y complejidad innecesaria. |
| `flatpak` | Similar a snap: añade una capa de empaquetado innecesaria para una distribución live técnica. |
| `ubuntu-report` / `popularity-contest` | Telemetría. Contradice el uso defensivo y la privacidad del usuario. |
| `calamares` | Instalador gráfico. PixelForge es una distribución live; la instalación en disco no es un objetivo del proyecto. |

\newpage

# Generación de la ISO — Flujo con Cubic (v1–v14)

## Arquitectura del host de construcción

| Parámetro | Valor |
|---|---|
| Host OS | Debian GNU/Linux (ARM64) |
| Plataforma | Máquina virtual Parallels sobre Apple Silicon |
| Cubic | Versión 2026.02 |
| Dependencias del host | `xorriso`, `squashfs-tools`, `qemu-system-aarch64`, `qemu-efi-aarch64` |

## Funcionamiento de Cubic

Cubic (Custom Ubuntu ISO Creator) es una herramienta GTK que automatiza el ciclo completo de personalización de ISOs live:

1. **Desempaquetado**: extrae el squashfs de la ISO base y monta un entorno chroot con `/proc`, `/sys`, `/dev` y `/run`.
2. **Personalización**: abre una terminal integrada donde el usuario ejecuta comandos dentro del sistema que será la futura ISO (instalación de paquetes, configuración de servicios, copia de archivos de branding).
3. **Reempaquetado**: al cerrar el chroot, ejecuta `mksquashfs` para comprimir el sistema modificado.
4. **Generación de ISO**: llama internamente a `xorriso` para producir la imagen ISO con el boot record EFI embebido.

## Personalización dentro del chroot

### Instalación de paquetes

```bash
apt update
apt install -y --no-install-recommends \
  xfce4 xfce4-goodies xfce4-terminal thunar thunar-archive-plugin \
  lightdm lightdm-gtk-greeter plymouth plymouth-themes \
  network-manager network-manager-gnome \
  wireshark nmap netcat-openbsd tcpdump \
  btop glances lsof iotop \
  gparted smartmontools \
  lynis fail2ban ufw chkrootkit \
  chntpw testdisk \
  iw wavemon \
  live-boot live-config \
  fastfetch
```

### Configuración de usuarios y autologin

```bash
useradd -m -s /bin/bash -u 1002 danielsson
echo 'danielsson:root' | chpasswd
usermod -aG sudo,wireshark,autologin,nopasswdlogin danielsson

useradd -m -s /bin/bash -u 1001 admin
echo 'admin:admin' | chpasswd
usermod -aG sudo,wireshark admin

# user ya existe con UID 1000
echo 'user:live' | chpasswd
usermod -aG sudo,wireshark,autologin,nopasswdlogin user

echo 'root:root' | chpasswd
echo 'pixelforge' > /etc/hostname
```

### Configuración de LightDM

Contenido de `/etc/lightdm/lightdm.conf`:

```ini
[Seat:*]
autologin-user=danielsson
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
autologin-session=xfce
```

## Limitaciones de Cubic descubiertas en v14

A partir de la versión v14, se identificó un problema crítico: Cubic genera una imagen `efi.img` de **32 MB** que fuerza el campo `Ldsiz=0` en el registro El-Torito de la ISO. Este valor es rechazado por Parallels Desktop como imagen de arranque inválida.

La investigación reveló que las ISOs de libre.debian.net utilizan una `efi.img` de solo **3.4 MB**, lo que produce un `Ldsiz=6848` (valor válido) y permite el arranque correcto en Parallels.

Esta limitación motivó el cambio de estrategia documentado en la sección siguiente.

\newpage

# Cambio de Estrategia: libre.debian.net (v15–v19)

## Motivación del cambio

El problema de la `efi.img` sobredimensionada generada por Cubic no era un error de configuración, sino una limitación estructural de la herramienta. La solución requería un control total sobre el proceso de generación de la ISO, específicamente sobre los flags de `xorriso` y la imagen EFI utilizada.

## Nueva base: debian-live-13.3.0-arm64-libre-xfce.iso

A partir de la versión v16, se adoptó como base la ISO `debian-live-13.3.0-arm64-libre-xfce.iso` procedente de **libre.debian.net**. Esta ISO presenta las siguientes ventajas:

- Imagen `efi.img` de **3.4 MB** con `Ldsiz=6848` (válido para todos los hipervisores probados).
- Layout estándar Debian live con `live/filesystem.squashfs`.
- Software 100% libre (rama `main` exclusivamente).
- Soporte nativo ARM64.

## Proceso de reconstrucción manual

El proceso de reconstrucción manual sigue estos pasos:

1. **Montaje de la ISO base** y extracción de su contenido a un directorio de trabajo.
2. **Extracción del squashfs** con `unsquashfs` para obtener el sistema de archivos raíz.
3. **Montaje del chroot** con bind mounts de `/proc`, `/sys`, `/dev` y `/run`.
4. **Personalización** idéntica a la realizada en Cubic: instalación de paquetes, configuración de usuarios, branding.
5. **Desmontaje del chroot** y limpieza.
6. **Recompresión del squashfs** con `mksquashfs -comp zstd -Xcompression-level 22 -b 1M`.
7. **Regeneración de la ISO** con `xorriso` y los flags correctos para compatibilidad GPT+APM.

\newpage

# Comando xorriso Canónico

El comando xorriso utilizado para generar la ISO final v19 es el siguiente:

```bash
xorriso -as mkisofs -R -r -J -joliet-long -l -iso-level 3 \
  -V "UDIT_PIXELFORGE" \
  -e boot/grub/efi.img -no-emul-boot \
  -append_partition 2 0xef boot/grub/efi.img \
  -appended_part_as_gpt -part_like_isohybrid \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -o output.iso .
```

**Explicación de cada flag:**

| Flag | Función |
|---|---|
| `-R -r` | Extensiones Rock Ridge para nombres de archivo POSIX largos y permisos Unix |
| `-J -joliet-long` | Extensiones Joliet para compatibilidad Windows con nombres largos |
| `-l -iso-level 3` | Permite archivos mayores de 4 GB dentro de la ISO |
| `-V "UDIT_PIXELFORGE"` | Establece el Volume ID para identificación por GRUB (`search --label`) |
| `-e boot/grub/efi.img` | Especifica la imagen de arranque EFI (El-Torito) |
| `-no-emul-boot` | Arranque sin emulación de disquete |
| `-append_partition 2 0xef` | Añade la partición EFI como partición 2 de tipo 0xEF |
| `-appended_part_as_gpt` | Expone la partición añadida como entrada GPT |
| `-part_like_isohybrid` | Genera tabla de particiones compatible con isohybrid |
| `-isohybrid-gpt-basdat` | Añade entrada GPT de tipo Basic Data para la ISO |
| `-isohybrid-apm-hfsplus` | Añade entrada Apple Partition Map para compatibilidad macOS |

Los flags `-isohybrid-gpt-basdat` y `-isohybrid-apm-hfsplus` fueron los últimos en añadirse (v19) y resolvieron los problemas de arranque en Parallels Desktop. Sin ellos, la ISO arrancaba en QEMU pero no en Parallels.

\newpage

# Personalización Visual

## Tema GTK y entorno de escritorio

| Elemento | Valor |
|---|---|
| Tema GTK | `catppuccin-mocha-blue-standard+default` |
| Iconos | Papirus-Dark |
| Cursor | Adwaita |
| Escritorio | XFCE 4.18 (`xfce4-session`, `xfwm4`, `xfdesktop4`, `xfce4-panel`) |
| Display Manager | LightDM con `lightdm-gtk-greeter` |

## Wallpapers

| Recurso | Resolución | Descripción |
|---|---|---|
| `wallpaper.png` | 2560x1440 | Edificio UDIT Gemini. Wallpaper principal del escritorio. |
| `login.png` | 2560x1440 | Hotel Andrea e Iván. Fondo del greeter de LightDM. |

## Plymouth

El tema Plymouth `pixelforge` muestra una animación de portal en estilo pixel art con una resolución nativa de 3640x2048. Se activa durante el arranque del sistema tras la selección en GRUB y permanece visible hasta que LightDM toma el control de la pantalla.

## LightDM Greeter

El greeter de LightDM utiliza un CSS personalizado con efecto de cristal (*glass effect*) basado en la paleta Catppuccin Mocha. El fondo es la imagen `login.png` que muestra el hotel donde se alojaron Andrea e Iván, a una resolución de 2560x1440.

## Panel XFCE

### Panel superior (28 px)

Disposición horizontal: menú de aplicaciones etiquetado como "PixelForge", lista de ventanas (tasklist), bandeja del sistema (systray), control de volumen PulseAudio, reloj del sistema y botones de acciones de energía.

### Dock inferior (48 px)

Panel de lanzadores rápidos con 14 aplicaciones organizadas por frecuencia de uso y categoría funcional:

| # | Lanzador | Función |
|---|---|---|
| 1 | Thunar | Gestor de archivos |
| 2 | Terminal | Emulador de terminal XFCE |
| 3 | Wireshark | Análisis de protocolos de red |
| 4 | Nmap | Escaneo de red |
| 5 | btop | Monitor de sistema |
| 6 | Glances | Monitor de sistema integral |
| 7 | GParted | Gestión de particiones |
| 8 | Lynis | Auditoría de seguridad |
| 9 | chkrootkit | Detección de rootkits |
| 10 | TestDisk | Recuperación de datos |
| 11 | Wavemon | Monitor WiFi |
| 12 | tcpdump | Captura de paquetes |
| 13 | AppFinder | Buscador de aplicaciones |
| 14 | ShowDesktop | Mostrar escritorio |

## MOTD y Fastfetch

El archivo `/etc/motd` contiene un banner ASCII art con el nombre UDIT PixelForge que se muestra en cada inicio de sesión de terminal. Además, Fastfetch se ejecuta automáticamente al abrir una terminal, proporcionando información del sistema (distribución, kernel, uptime, memoria, CPU) con formato visual.

## Usuarios del sistema

| Usuario | Contraseña | UID | Grupos | Notas |
|---|---|---|---|---|
| `danielsson` | `root` | 1002 | `sudo`, `wireshark`, `autologin`, `nopasswdlogin` | Usuario de autologin predeterminado |
| `user` | `live` | 1000 | `sudo`, `wireshark`, `autologin`, `nopasswdlogin` | Usuario estándar live |
| `admin` | `admin` | 1001 | `sudo`, `wireshark` | Usuario administrativo |
| `root` | `root` | 0 | — | Superusuario |

\newpage

# Optimización del Sistema

## Estrategia de eliminación

| Categoría | Acción realizada |
|---|---|
| Caché de paquetes APT | `apt clean` tras la instalación (libera ~150 MB) |
| Listas APT | `rm -rf /var/lib/apt/lists/*` |
| Snap / Flatpak | Nunca instalados |
| Suites ofimáticas | No instaladas (LibreOffice, etc.) |
| Navegador web | No incluido (Firefox ESR omitido para mantener tamaño) |
| Telemetría | No presente (ventaja inherente de Debian) |
| Firmware propietario | Solo firmware libre |

## Estrategia de retención

Se mantienen los siguientes componentes que, aunque añaden tamaño, son esenciales para el perfil funcional de la distribución:

- **XFCE completo** con `xfce4-goodies`: los plugins de panel (sensors, cpugraph, netload) son coherentes con el rol de diagnóstico.
- **NetworkManager con applet GNOME**: necesario para la gestión visual de conexiones en el panel.
- **Wireshark con GUI completa**: `xserver-xorg` y dependencias gráficas son necesarias para la interfaz de Wireshark, corregido en v19.
- **Fastfetch**: utilidad ligera que proporciona información del sistema al abrir la terminal.

## Compresión del squashfs

| Parámetro | Valor |
|---|---|
| Algoritmo | zstd |
| Nivel de compresión | 22 (máximo) |
| Tamaño de bloque | 1 MB |

La elección de zstd nivel 22 ofrece un ratio de compresión comparable a XZ pero con tiempos de descompresión significativamente menores durante el arranque, lo que mejora la experiencia del usuario al reducir el tiempo hasta el escritorio.

## Persistencia opcional

Debian live soporta persistencia nativa sin modificar la ISO. Para activarla, se crea una segunda partición en el USB:

```bash
sudo mkfs.ext4 -L persistence /dev/sdXN
sudo mount /dev/sdXN /mnt
echo "/ union" | sudo tee /mnt/persistence.conf
sudo umount /mnt
```

Y se arranca añadiendo el parámetro `persistence` a la línea del kernel en GRUB.

## Resultado cuantitativo

- 1564 paquetes instalados.
- Squashfs comprimido con zstd nivel 22.
- ISO final: **989 MB**.

\newpage

# Problemas Encontrados y Resoluciones

## Historial de iteraciones v1 a v19

La versión entregada es la **v19**. Las 19 iteraciones documentan la evolución del proyecto desde los primeros intentos con Cubic hasta la ISO final validada en múltiples hipervisores.

### Fase Cubic (v1–v14)

| Versión | Fecha | Tamaño | Síntoma / Cambio | Resolución |
|---|---|---|---|---|
| v1 | 12 abr | — | Cubic no reconocía el layout Debian | Actualización a Cubic 2026.02 que detecta `live/` |
| v2 | 12 abr | — | Kernel panic `no init` | Añadir `live-boot` y `live-config` al bloque `apt install` |
| v3 | 12 abr | — | Sesión XFCE no se abría | Incluir metapaquete `xfce4` completo con `xfce4-session` |
| v4 | 12 abr | — | LightDM en bucle de login | Crear el usuario antes de configurar `lightdm.conf` |
| v5 | 12 abr | — | Plymouth no mostraba tema | Ejecutar `update-initramfs -u` tras `plymouth-set-default-theme` |
| v6 | 12 abr | — | Wireshark no ejecutable como usuario | `usermod -aG wireshark user` |
| v7 | 12 abr | — | Locale mixto ES/EN | `dpkg-reconfigure locales` con `es_ES.UTF-8` |
| v8 | 12 abr | 797 MB | Primer *release candidate* con Cubic | Arranque estable, XFCE, herramientas operativas |
| v9–v13 | 12 abr | varios | Iteraciones de ajuste de branding y paquetes | Refinamiento progresivo |
| v14 | 12 abr | 945 MB | Último build con Cubic | `efi.img` de 32 MB → `Ldsiz=0` → fallo en Parallels |

### Fase manual sobre libre.debian.net (v15–v19)

| Versión | Fecha | Tamaño | Síntoma / Cambio | Resolución |
|---|---|---|---|---|
| v15 | 14 abr | 927 MB | Primera reconstrucción manual | Aún fallaba en Parallels por flags de xorriso incompletos |
| v16 | 15 abr | 2.8 GB → 1.2 GB | Cambio a base libre.debian.net | Corrige arranque en Parallels. Tamaño inicial alto, se optimiza |
| v17 | 15 abr | — | Ajustes intermedios | Iteraciones de configuración |
| v18 | 15 abr | 883 MB | Build reducido | Faltaban flags GPT/APM en xorriso |
| v19 | 16 abr | 989 MB | **ISO FINAL** | Correcciones: `xserver-xorg`, GUI de Wireshark, flags GPT+APM, wallpapers 2K, panel XFCE completo |

## Problemas técnicos clave y sus soluciones

### Problema 1: efi.img sobredimensionada de Cubic

Cubic genera una `efi.img` de 32 MB que fuerza `Ldsiz=0` en el registro El-Torito. Parallels Desktop rechaza este valor como imagen de arranque inválida.

**Solución:** adoptar la base de libre.debian.net que incluye una `efi.img` de 3.4 MB con `Ldsiz=6848` (válido).

### Problema 2: Wireshark sin interfaz gráfica

En v18, Wireshark estaba instalado pero no podía mostrar su GUI porque faltaba `xserver-xorg` y sus dependencias.

**Solución:** añadir `xserver-xorg` explícitamente en el bloque de instalación de paquetes en v19.

### Problema 3: Falta de flags GPT y APM en xorriso

Las versiones v15–v18 no incluían los flags `-isohybrid-gpt-basdat` ni `-isohybrid-apm-hfsplus`, lo que provocaba que la ISO no fuese reconocida como arrancable por Parallels.

**Solución:** añadir ambos flags al comando xorriso en v19.

### Problema 4: Wallpapers de baja resolución

Las versiones anteriores utilizaban wallpapers de resolución inferior que se veían pixelados en pantallas Retina de Apple Silicon.

**Solución:** generar wallpapers nativos a 2560x1440 para v19.

\newpage

# Pruebas Realizadas

## Estrategia de prueba

Se adopta una estrategia de prueba dual: validación en **QEMU aarch64** (entorno controlado, reproducible) y en **Parallels Desktop** (entorno de uso real del equipo de desarrollo sobre Apple Silicon).

## Prueba en QEMU aarch64

Comando de arranque utilizado:

```bash
qemu-system-aarch64 \
  -machine virt,gic-version=max \
  -accel tcg,thread=multi \
  -cpu max \
  -smp 2 \
  -m 2048 \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -device virtio-gpu-pci \
  -device qemu-xhci \
  -device usb-kbd \
  -device usb-mouse \
  -drive if=none,id=cd,file="debian-udit-pixelart-arm64-v19-final.iso",media=cdrom,format=raw \
  -device virtio-blk-pci,drive=cd \
  -display gtk \
  -serial mon:stdio
```

**Resultado:** arranque satisfactorio. GRUB muestra las 4 entradas, Plymouth se visualiza, XFCE carga con autologin, todas las herramientas responden.

## Prueba en Parallels Desktop (Apple Silicon)

Se creó una máquina virtual ARM64 en Parallels Desktop sobre un Mac con Apple Silicon, asignando 2 GB de RAM y 2 vCPU. La ISO v19 se montó como unidad óptica virtual.

**Resultado:** arranque satisfactorio. La ISO es reconocida como arrancable gracias a los flags GPT+APM del comando xorriso. El sistema funciona con rendimiento nativo gracias a la virtualización hardware de Apple Silicon.

## Checklist de validación

| Prueba | Resultado QEMU | Resultado Parallels |
|---|---|---|
| Menú GRUB visible con 4 entradas | OK | OK |
| Plymouth pixelforge visible | OK | OK |
| Autologin del usuario danielsson | OK | OK |
| Escritorio XFCE con wallpaper correcto | OK | OK |
| Panel superior con reloj y systray | OK | OK |
| Dock inferior con 14 lanzadores | OK | OK |
| Wireshark GUI funcional | OK | OK |
| Nmap operativo | OK | OK |
| btop operativo | OK | OK |
| GParted operativo | OK | OK |
| Lynis operativo | OK | OK |
| chkrootkit operativo | OK | OK |
| TestDisk operativo | OK | OK |
| Fastfetch en terminal | OK | OK |
| MOTD ASCII visible | OK | OK |
| Tema Catppuccin Mocha aplicado | OK | OK |
| Iconos Papirus-Dark visibles | OK | OK |

\newpage

# Consumo de Recursos

| Magnitud | Valor |
|---|---|
| RAM mínima para arrancar (modo texto) | 512 MB |
| RAM mínima recomendada (XFCE fluido) | 1 GB |
| RAM óptima (XFCE + Wireshark + herramientas) | 2 GB |
| CPU recomendada | Dual-core 1.5 GHz ARM64 |
| Espacio en USB | 1 GB (989 MB ISO) |
| Espacio en disco si se instala | 4 GB mínimo, 8 GB recomendado |

**Base del cálculo:** XFCE idle en Debian 13 consume aproximadamente 250 MB de RAM. LightDM añade ~60 MB, systemd con NetworkManager ~100 MB, y el overhead del overlayfs sobre el squashfs ~80 MB. El total idle estimado es de **~490 MB**, lo que deja margen operativo con 1 GB de RAM para abrir herramientas individuales y con 2 GB para uso simultáneo de Wireshark con capturas de red activas.

\newpage

# Verificación de Requisitos

Tabla de cumplimiento unificada. Cada fila es auditable en los artefactos entregados.

| ID | Requisito del enunciado | Cumplido | Evidencia / Sección |
|---|---|---|---|
| R1 | Ligera en consumo de recursos | Si | 1564 paquetes, 989 MB ISO, idle ~490 MB RAM |
| R2 | Funcional en hardware limitado | Si | Arranca en 512 MB (texto), 1 GB (XFCE) |
| R3 | Portable en USB o instalable | Si | Live Debian estándar, `dd` a USB |
| R4 | Orientada a tareas técnicas | Si | 22+ herramientas en sección 9 |
| R5 | Base Debian | Si | Debian 13.3 trixie arm64 |
| R6 | Interfaz gráfica ligera | Si | XFCE 4.18 |
| R7 | Arranque estable | Si | GRUB EFI con 4 entradas, probado en 2 hipervisores |
| R8 | Nombre de la distribución | Si | UDIT PixelForge |
| R9 | Objetivo documentado | Si | Secciones 2 y 3 |
| R10 | Perfil de usuario definido | Si | Sección 7 |
| R11 | Justificación de la base | Si | Sección 5 |
| R12 | Estrategia de optimización | Si | Sección 15 |
| R13 | Consumo estimado de recursos | Si | Sección 18 |
| R14 | Herramientas reales sin redundancia | Si | Secciones 9 y 10 |
| R15 | Persistencia opcional | Si | Sección 15 |
| R16 | Entorno limpio | Si | Sección 15 |
| R17 | Documentación técnica | Si | Este documento |

\newpage

# Compatibilidad de Hipervisores

| Hipervisor | Plataforma | Estado | Notas |
|---|---|---|---|
| Parallels Desktop | Apple Silicon (macOS) | Probado y funcional | Requiere flags GPT+APM en xorriso |
| QEMU aarch64 | Cualquier host (Linux, macOS, Windows) | Probado y funcional | Requiere firmware UEFI (`QEMU_EFI.fd`) |
| UTM | macOS | Compatible (basado en QEMU) | No probado directamente, pero usa el mismo backend QEMU |
| VirtualBox ARM64 | Experimental | Fuera de alcance | Soporte ARM64 de VirtualBox es experimental |
| Hardware ARM64 real | Equipos con firmware UEFI | Debería funcionar | No probado por falta de hardware disponible |

La compatibilidad con Parallels Desktop fue el principal reto técnico del proyecto, resuelto en v19 mediante la adopción de la base libre.debian.net y los flags `xorriso` correctos para GPT+APM.

\newpage

# Conclusiones

UDIT PixelForge demuestra que un equipo de dos personas puede entregar, en un plazo razonable, una distribución Linux basada en Debian funcional, ligera y con identidad visual propia, siempre que el flujo de construcción se apoye en herramientas maduras y la selección de paquetes se mantenga disciplinada.

Los puntos más relevantes del proyecto son los siguientes:

1. **La decisión de usar Debian como base se reveló acertada.** Los repositorios estables, la ausencia de telemetría, la compatibilidad con herramientas de construcción de ISOs y la coherencia con el host ARM64 nativo del equipo de desarrollo respaldaron esta elección durante las 19 iteraciones.

2. **El cambio de Cubic a reconstrucción manual fue necesario y beneficioso.** Cubic facilitó las primeras 14 iteraciones al automatizar el ciclo chroot-squashfs-xorriso, pero su generación de `efi.img` sobredimensionada era incompatible con Parallels Desktop. La migración a un proceso manual con base libre.debian.net otorgó control total sobre los flags de xorriso y permitió resolver el problema de arranque.

3. **La iteración intensiva fue fundamental.** Los 19 ciclos de construcción y prueba no fueron accidentales: cada versión resolvió uno o más problemas concretos (kernel panic, autologin en bucle, Plymouth sin tema, Wireshark sin GUI, flags EFI incorrectos). El conocimiento técnico del equipo se construyó empíricamente en cada iteración.

4. **La identidad visual profesional es alcanzable sin complejidad excesiva.** El tema Catppuccin Mocha, los iconos Papirus-Dark, el Plymouth personalizado, el greeter con efecto cristal, los wallpapers de producción propia y el panel con dock de herramientas conforman una experiencia visual coherente y reconocible que se integra en el sistema mediante archivos de configuración estándar de XFCE y LightDM.

5. **La validación en dos hipervisores distintos aporta confianza.** Probar en QEMU y Parallels Desktop sobre Apple Silicon cubre dos modos de virtualización diferentes (emulación TCG y virtualización nativa), lo que aumenta la confianza en que la ISO funcionará en otros entornos ARM64 compatibles con UEFI.

6. **Todos los requisitos del enunciado se cumplen.** La tabla de verificación de la sección 19 confirma el cumplimiento de los 17 requisitos identificados, con evidencia auditable para cada uno.

La versión entregada (v19) es la versión final del proyecto y cumple todos los requisitos obligatorios del enunciado.

\newpage

# Anexos

## Anexo A — Comandos de auditoría de la ISO

```bash
# A.1 Verificar integridad de la ISO
sha256sum debian-udit-pixelart-arm64-v19-final.iso
# Resultado esperado: 57bbc10bd5626aa3f7d2f3379da6cbb5b9e32964dd4e058d07bb9df43c6b33c3

# A.2 Verificar tamaño
ls -lh debian-udit-pixelart-arm64-v19-final.iso
# Resultado esperado: 989M

# A.3 Verificar estructura ISO con xorriso
xorriso -indev debian-udit-pixelart-arm64-v19-final.iso -toc
# Debe mostrar Volume ID: UDIT_PIXELFORGE, El-Torito boot record, efi.img

# A.4 Montar la ISO y explorar contenido
mkdir -p /tmp/iso_mount
sudo mount -o loop,ro debian-udit-pixelart-arm64-v19-final.iso /tmp/iso_mount
ls /tmp/iso_mount/
# Resultado: boot  EFI  live
ls /tmp/iso_mount/live/
# Resultado: filesystem.squashfs  initrd.img  vmlinuz

# A.5 Extraer metadata del squashfs
sudo unsquashfs -d /tmp/sq_meta -f /tmp/iso_mount/live/filesystem.squashfs \
  etc/os-release etc/hostname etc/debian_version \
  var/lib/dpkg/status

# A.6 Contar paquetes instalados
grep -c '^Package:' /tmp/sq_meta/var/lib/dpkg/status
# Resultado esperado: 1564

# A.7 Verificar herramientas obligatorias
for p in wireshark nmap netcat-openbsd tcpdump btop glances lsof iotop \
         gparted smartmontools lynis fail2ban ufw chkrootkit chntpw \
         testdisk iw wavemon network-manager xfce4 lightdm live-boot; do
  grep -q "^Package: $p$" /tmp/sq_meta/var/lib/dpkg/status && \
    echo "[OK] $p" || echo "[FALTA] $p"
done

# A.8 Limpiar
sudo umount /tmp/iso_mount
sudo rm -rf /tmp/sq_meta /tmp/iso_mount
```

## Anexo B — Comandos de construcción (reproducibles)

```bash
# B.1 Dependencias del host
sudo apt update
sudo apt install -y xorriso squashfs-tools \
  qemu-system-arm qemu-efi-aarch64 rsync

# B.2 Extraer la ISO base
ISO_BASE="debian-live-13.3.0-arm64-libre-xfce.iso"
WORK_DIR="/tmp/pixelforge_build"
mkdir -p "$WORK_DIR/iso" "$WORK_DIR/rootfs"

sudo mount -o loop,ro "$ISO_BASE" /mnt
rsync -av /mnt/ "$WORK_DIR/iso/"
sudo umount /mnt

# B.3 Extraer el squashfs
sudo unsquashfs -d "$WORK_DIR/rootfs" "$WORK_DIR/iso/live/filesystem.squashfs"

# B.4 Montar el chroot
sudo mount --bind /proc "$WORK_DIR/rootfs/proc"
sudo mount --bind /sys "$WORK_DIR/rootfs/sys"
sudo mount --bind /dev "$WORK_DIR/rootfs/dev"
sudo mount --bind /run "$WORK_DIR/rootfs/run"

# B.5 Entrar al chroot y personalizar
sudo chroot "$WORK_DIR/rootfs" /bin/bash
# (ejecutar comandos de instalación y configuración dentro del chroot)
# (ver secciones 11 y 14 para detalles)
exit

# B.6 Desmontar el chroot
sudo umount "$WORK_DIR/rootfs/run"
sudo umount "$WORK_DIR/rootfs/proc"
sudo umount "$WORK_DIR/rootfs/sys"
sudo umount "$WORK_DIR/rootfs/dev"

# B.7 Recomprimir el squashfs
sudo rm -f "$WORK_DIR/iso/live/filesystem.squashfs"
sudo mksquashfs "$WORK_DIR/rootfs" "$WORK_DIR/iso/live/filesystem.squashfs" \
  -comp zstd -Xcompression-level 22 -b 1M -noappend

# B.8 Regenerar la ISO
cd "$WORK_DIR/iso"
xorriso -as mkisofs -R -r -J -joliet-long -l -iso-level 3 \
  -V "UDIT_PIXELFORGE" \
  -e boot/grub/efi.img -no-emul-boot \
  -append_partition 2 0xef boot/grub/efi.img \
  -appended_part_as_gpt -part_like_isohybrid \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -o /tmp/debian-udit-pixelart-arm64-v19-final.iso .
```

## Anexo C — Prueba en QEMU (reproducible)

```bash
qemu-system-aarch64 \
  -machine virt,gic-version=max \
  -accel tcg,thread=multi \
  -cpu max -smp 2 -m 2048 \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -device virtio-gpu-pci \
  -device qemu-xhci -device usb-kbd -device usb-mouse \
  -drive if=none,id=cd,file="debian-udit-pixelart-arm64-v19-final.iso",media=cdrom,format=raw \
  -device virtio-blk-pci,drive=cd \
  -display gtk -serial mon:stdio
```

## Anexo D — Generación del PDF desde este documento

```bash
# Requisitos: pandoc + texlive-xetex
sudo apt install -y pandoc texlive-xetex texlive-lang-spanish

# Generar PDF
cd memoria/
pandoc MEMORIA.md -o MEMORIA.pdf \
  --pdf-engine=xelatex \
  --toc --toc-depth=3 \
  -V mainfont="DejaVu Sans" \
  -V monofont="DejaVu Sans Mono" \
  -V geometry:margin=2.3cm \
  -V documentclass=article \
  -V fontsize=11pt \
  -V lang=es
```

## Anexo E — Comandos de auditoría de seguridad dentro del live

```bash
# E.1 Auditoría completa con Lynis
sudo lynis audit system --quick

# E.2 Detección de rootkits
sudo chkrootkit

# E.3 Estado del firewall
sudo ufw status verbose

# E.4 Estado de Fail2Ban
sudo fail2ban-client status

# E.5 Escaneo de red local
nmap -sn 192.168.1.0/24

# E.6 Captura de tráfico (10 segundos)
sudo tcpdump -i any -c 100 -w /tmp/captura.pcap

# E.7 Monitor de procesos
btop

# E.8 Monitor integral del sistema
glances

# E.9 Información SMART del disco
sudo smartctl -a /dev/sda

# E.10 Información WiFi
iw dev
wavemon
```

\newpage

# Glosario

- **ARM64 (aarch64)**: arquitectura de procesador de 64 bits basada en el diseño ARM, utilizada en Apple Silicon, Raspberry Pi 4+, servidores Graviton de AWS y muchos dispositivos embebidos. UDIT PixelForge está compilada exclusivamente para esta arquitectura.

- **Catppuccin Mocha**: paleta de colores de código abierto diseñada para terminales e interfaces de usuario. La variante Mocha es la más oscura, con fondo `#1e1e2e` y acentos pastel que reducen la fatiga visual.

- **Chroot**: mecanismo del kernel Linux que cambia la raíz del sistema de archivos visible a un proceso. Se utiliza durante la construcción de la ISO para operar sobre el rootfs de la futura distribución como si fuese el sistema vivo.

- **Cubic**: Custom Ubuntu ISO Creator. Asistente GTK que orquesta el flujo `unsquashfs` → chroot → `mksquashfs` → `xorriso` para personalizar ISOs live. Aunque diseñado para Ubuntu, funciona con ISOs Debian que usan el layout `live/`.

- **El-Torito**: especificación ISO 9660 que permite que una imagen ISO contenga un *boot image* arrancable desde BIOS o UEFI. El campo `Ldsiz` indica el tamaño de la imagen de arranque en sectores de 512 bytes.

- **GPT (GUID Partition Table)**: esquema de particionado moderno que reemplaza a MBR. Los flags `-isohybrid-gpt-basdat` en xorriso aseguran que la ISO sea reconocida como disco arrancable por firmware UEFI.

- **APM (Apple Partition Map)**: esquema de particionado utilizado históricamente por Apple. El flag `-isohybrid-apm-hfsplus` en xorriso asegura compatibilidad con el firmware de equipos Apple.

- **Isohybrid**: técnica que permite que una imagen ISO sea arrancable tanto desde un lector óptico como desde un dispositivo USB, mediante la inyección de un MBR y/o tablas de particiones GPT/APM en la imagen.

- **libre.debian.net**: servicio que proporciona imágenes Debian live construidas exclusivamente con software de la rama `main` (libre). Las ISOs de este servicio no incluyen firmware propietario.

- **live-boot**: conjunto de scripts de Debian que permiten arrancar un sistema operativo desde una imagen ISO o USB sin instalación previa, montando el squashfs como raíz mediante overlayfs.

- **LightDM**: display manager ligero que gestiona el proceso de inicio de sesión gráfica. Soporta autologin y temas personalizados mediante el greeter GTK.

- **Overlayfs**: sistema de archivos en capas del kernel Linux. Debian live lo monta encima del squashfs (solo lectura) para proporcionar la ilusión de escritura durante la sesión live. Los cambios se almacenan en RAM y se pierden al apagar, salvo que se active persistencia.

- **Papirus-Dark**: tema de iconos de código abierto con estilo material design en variante oscura. Proporciona iconos consistentes para aplicaciones GTK y Qt.

- **Plymouth**: sistema de splash screen del kernel Linux que muestra una animación o imagen durante el arranque, ocultando los mensajes de inicio del kernel.

- **Squashfs**: sistema de archivos comprimido y de solo lectura. Debian live almacena todo el sistema operativo en un único archivo `filesystem.squashfs` que el kernel monta al arrancar.

- **UEFI (Unified Extensible Firmware Interface)**: estándar de firmware que reemplaza al BIOS tradicional. Todas las máquinas ARM64 modernas utilizan UEFI para el arranque.

- **xorriso**: herramienta de línea de comandos para crear, modificar y grabar imágenes ISO 9660. En este proyecto se utiliza para generar la ISO final con los registros de arranque EFI correctos.

- **XFCE**: entorno de escritorio ligero para sistemas Unix. La versión 4.18 utilizada en PixelForge consume aproximadamente 250 MB de RAM en reposo, lo que lo hace adecuado para una distribución orientada a hardware limitado.

- **zstd (Zstandard)**: algoritmo de compresión desarrollado por Facebook/Meta. Ofrece ratios de compresión similares a XZ con velocidades de descompresión significativamente superiores, lo que reduce el tiempo de arranque del sistema live.

---

*Documento elaborado por Andrea e Iván como memoria técnica del proyecto final de Sistemas Operativos Avanzados. UDIT — Universidad de Diseño, Innovación y Tecnología. Abril 2026.*
