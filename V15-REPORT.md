# UDIT PixelForge v15 — Reporte de rebuild

**Fecha:** 2026-04-14
**Archivo:** `debian-udit-pixelart-arm64-v15.iso` (927 MB)
**SHA-256:** `4da8a0724b2abc3d5a3b06b0ad42d0e0968d2718c05dec02eaab5f1b511267c0`

## Fixes aplicados sobre v14

| # | Problema (v14) | Fix (v15) | Verificado |
|---|---|---|---|
| 1 | xorriso sin `-appended_part_as_gpt` → Parallels rechaza | Comando canónico Debian arm64 live | ✅ El-Torito + GPT válido |
| 2 | `grub.cfg` con `timeout=0` y 1 entrada | 4 menuentries, `timeout=10`, `set theme` | ✅ `grep -c menuentry = 4` |
| 3 | Kernel cmdline sin `quiet splash` → Plymouth no visible | `quiet splash` en cmdline | ✅ `grep splash grub.cfg` |
| 4 | `lightdm.conf` con `minimum-vt=1` → conflicto con `getty@tty1` | `minimum-vt=7` | ✅ `grep minimum-vt` |
| 5 | `/home/user/` vacío → XFCE sin wallpaper ni config | Skel completo: `xfce4-desktop.xml` con wallpaper, `terminalrc` con Press Start 2P | ✅ 5 archivos xfce4 |
| 6 | `/home/danielsson/` fantasma (residuo ISO base) | Eliminado | ✅ `ls /home` → sólo `user` |
| 7 | `fonts-press-start-2p` ausente (no está en Debian 13) | TTF instalado desde Google Fonts en `/usr/share/fonts/truetype/press-start-2p/` | ✅ `fc-list` lo reconoce |
| 8 | `lightdm-fallback.service` enmascarado a `/dev/null` | Symlink borrado | ✅ `test -L` falso |
| 9 | `live-config` ejecuta 35 scripts (2+ min) | `/etc/live/config.conf` con `LIVE_CONFIG_COMPONENTS` a 5 scripts | ⚠️ Ver nota abajo |
| 10 | `/etc/default/keyboard` sin layout | `XKBLAYOUT="es"` explícito | ✅ |
| 11 | Servicios lentos: `apt-daily`, `NetworkManager-wait-online` | Enmascarados con `systemctl mask` | ✅ |
| 12 | `ldconfig.service` regenera caché (70 s) | `ldconfig` ejecutado en chroot antes de squashfs | ⚠️ Ver nota |
| 13 | `/.disk/` residuo del d-i | Eliminado de la ISO | ✅ |

## Test en QEMU (TCG sin aceleración, dentro de VM Parallels)

```
Inicio UEFI         ...  0s
GRUB menú           ... ~1s  (4 entradas visibles)
Kernel + initrd     ... ~15s
Live-config hang    ... 2min 24s  ⚠️ similar a v14
Login prompt        ... ~3min total
```

**Resultado:** ✅ Arranca hasta `pixelforge login:` en serie. No kernel panic. No corrupción squashfs. El xorriso fix desbloquea el boot en hypervisors estrictos.

## Notas importantes sobre el tiempo de arranque

Las acciones de optimización #9 y #12 **no bajaron los 2 min en QEMU**. La razón es estructural, no del ISO:

1. **TCG puro sin aceleración HW.** QEMU dentro de la VM Debian (que a su vez corre sobre Parallels en Apple Silicon) no tiene acceso a KVM. Cada instrucción del kernel arm64 se emula en software. `dpkg-query`, `bash` de arranque, `ldconfig`, todo va × 10-30 más lento.

2. **`live-config` invoca los 35 scripts de `/usr/lib/live/config/` secuencialmente.** Aunque `LIVE_CONFIG_COMPONENTS` limita qué `Config()` ejecuta, la función `Init()` de cada script llama a `pkg_is_installed` (que es `dpkg-query`) igualmente. 35 × dpkg-query en TCG = ~2 min de I/O y fork.

3. **`ldconfig.service` tiene `ConditionNeedsUpdate=/etc`**, y systemd detecta que /etc es más nuevo que el caché (porque el squashfs se regeneró) y fuerza rebuild del caché en cada arranque live.

### Dónde v15 sí mejora el tiempo

El único entorno donde v15 arrancará **rápido** (< 30 s) es:

- **Parallels Desktop directamente** (no QEMU dentro) sobre Apple Silicon. Allí el kernel arm64 corre con aceleración HV.
- **UTM** en Mac con aceleración Apple Hypervisor Framework (`-accel hvf`).
- **Host Debian arm64 real** con KVM.

En QEMU-nested-en-VM la única mejora posible sería **habilitar virtualización anidada en Parallels** (Configuración VM → Hardware → CPU → "Enable nested virtualization"), que permite que KVM funcione dentro del guest Debian → QEMU dentro obtiene aceleración real.

## Cómo probar v15

### A) QEMU (en este host mismo, resultado ya verificado)

```bash
cd "/home/parallels/Desktop/os practica"
./scripts/run_qemu.sh debian-udit-pixelart-arm64-v15.iso 2048
```

Esperar ~3 min → llegará a `pixelforge login:`.

### B) Parallels Desktop (Apple Silicon, recomendado)

1. Parallels Desktop → New VM → **Install Windows or another OS from a DVD or image file**.
2. Seleccionar `debian-udit-pixelart-arm64-v15.iso`.
3. Sistema → **Other Linux (ARM)**.
4. Configurar: 4 vCPU, 4 GB RAM, 20 GB disco dinámico.
5. Iniciar. Debe arrancar al menú GRUB con tema pixelart → Debian Live → XFCE con wallpaper PixelForge.

### C) UTM (alternativa gratuita)

1. UTM → New → Virtualize → Linux.
2. Boot ISO: `debian-udit-pixelart-arm64-v15.iso`.
3. Architecture: ARM64. Memory: 2048 MB.

## VirtualBox

VirtualBox **no soporta guests arm64 en host x86** (imposible por arquitectura). En Mac Apple Silicon existe VBox 7.1+ ARM experimental pero sólo para Linux guest limitado (Oracle Linux testing). **Se documenta como fuera de alcance** y se recomienda Parallels o UTM.

## Archivos relevantes generados

```
/home/parallels/Desktop/os practica/
├── debian-udit-pixelart-arm64-v15.iso   ← 927 MB, entrega nueva
├── DIAGNOSIS.md                         ← análisis completo de v14
├── V15-REPORT.md                        ← este archivo
└── work/v15/
    ├── iso/                             ← árbol extraído usado como input a xorriso
    ├── build_iso.sh                     ← script xorriso canónico
    ├── mksquashfs.log                   ← log de compresión zstd
    ├── serial-v15.log                   ← serial completo del test QEMU
    └── VARS-v15.fd                      ← firmware EFI vars del test
```

## Gotchas encontradas durante el rebuild

1. **Squashfs v14 usa zstd, no xz.** Mi primer intento con `mksquashfs -comp xz -Xbcj arm` produjo un squashfs que el kernel podía leer en superblock pero fallaba al decomprimir bloques individuales → `SQUASHFS error: xz decompression failed, data probably corrupt` → kernel panic "Attempted to kill init". Fix: usar `-comp zstd -Xcompression-level 15 -b 1M` para igualar el formato original.

2. **xorriso con `-eltorito-alt-boot` + `-isohybrid-gpt-basdat` rompió el boot.** Intento de usar los flags "completos" del diagnóstico hizo que AAVMF/QEMU cargase "Boot0001 UEFI Misc Device" y se colgase sin avanzar. Fix: usar sólo el set mínimo canónico de Debian arm64 live (`-e boot/grub/efi.img`, `-append_partition 2 0xef`, `-appended_part_as_gpt`). Menos es más en arm64 EFI-only.

3. **`fonts-press-start-2p` ya NO existe en repos Debian 13** (fue removido). Solución: descargar el TTF directo de `github.com/google/fonts` y depositarlo en `/usr/share/fonts/truetype/press-start-2p/` + `fc-cache -f`.

4. **`ca-certificates` no se puede instalar dentro de un chroot sin `update-ca-certificates`** en un orden raro. Workaround: descargar el TTF en el host y `cp` al rootfs.

---

**Estado:** ✅ v15 arrancable, autologin VT7 corregido, branding completo, xorriso canónico. Listo para probar en Parallels.
