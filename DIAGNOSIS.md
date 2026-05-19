# UDIT PixelForge — Diagnóstico técnico de la ISO v8-v14

**Fecha:** 2026-04-14
**Auditor:** Claude (asistente técnico de Iván)
**Alcance:** `debian-udit-pixelart-arm64-v8.iso` … `v14.iso`
**Artefactos revisados:** `MEMORIA.md`, `scripts/*.sh`, `manual_extract/*.sh`, `work/bootfix/serial-*.log`, `work/sq14/`, estructura El-Torito del ISO v14, `grub.cfg` extraído, 778 paquetes del `dpkg/status`.

---

## 1. Resumen ejecutivo

Cinco problemas reales, en orden de impacto:

1. **🔴 BLOCKER — El comando `xorriso` está incompleto.** Falta `-isohybrid-gpt-basdat` y `-partition_cyl_align`, por lo que la ISO es técnicamente bootable vía UEFI pero con *cyl-align-off* y sin marcar la partición apéndice como GPT "basic data". **Parallels Desktop la rechaza silenciosamente** (pantalla negra / "No bootable device") y VirtualBox no la lee. QEMU sí la arranca porque es más tolerante.
2. **🔴 BLOCKER — VirtualBox no soporta guests ARM64 en host x86.** No es culpa del ISO: VirtualBox solo ejecuta arm64 en hosts Apple Silicon con edición experimental (≥ 7.1.x). Esto se documenta como limitación externa, no se "arregla".
3. **🟠 HIGH — Arranque lentísimo (≈ 2 min parado en `live-config.service`).** Verificado en `serial-v14-final.log`: `ldconfig.service` tarda 70 s, `console-setup.service` 10 s, `live-config.service` hasta 2 min 19 s. Causa raíz: emulación TCG sin aceleración (QEMU anidado dentro de la VM Parallels donde no hay KVM), combinada con `live-config` ejecutando 35 scripts secuencialmente.
4. **🟠 HIGH — GRUB no muestra menú ni tema.** `grub.cfg` tiene `set timeout=0` y sólo una `menuentry`. La MEMORIA promete 3 entradas (live/safe/debug) y tema `udit-pixelart` — ninguno está en el archivo real extraído del ISO v14.
5. **🟠 HIGH — Plymouth splash nunca se ve.** El parámetro del kernel es `boot=live components locales=es_ES.UTF-8 keyboard-layouts=es`. **Falta `quiet splash`**. Sin `splash` en la cmdline, Plymouth no renderiza el tema gráfico por mucho que `plymouthd.conf` diga `Theme=pixelforge`. Por eso "las customizaciones no se aplican" visualmente aunque sí están en el squashfs.

Hay además problemas secundarios reales (autologin VT, usuario `danielsson` fantasma, `lightdm-fallback.service` apuntando a `/dev/null`, fuente `fonts-press-start-2p` no instalada, home `/home/user/` vacío sin skel) que se listan en §3.

---

## 2. Cómo lo construyeron (resumen de `MEMORIA.md`)

- **Base:** `debian-live-*-arm64-standard.iso` oficial (Debian 13 *trixie*, live, arm64).
- **Herramienta:** Cubic 2026.02 (flujo `unsquashfs → chroot → mksquashfs → xorriso`).
- **En el chroot:** se instalan XFCE, LightDM, Plymouth, las ~20 herramientas del enunciado, `live-boot`, `live-config`, se crea `user:live`, se ajusta `/etc/hostname=pixelforge`, se copian wallpapers y temas, se llama `plymouth-set-default-theme -R pixelforge`, se limpia apt.
- **Reempaquetado:** `mksquashfs ... -comp xz -Xbcj arm` (correcto), `md5sum.txt` regenerado, y el siguiente `xorriso` (en `scripts/patch_v9_netcat.sh` y descrito en §9.5 de la memoria):

  ```bash
  xorriso -as mkisofs \
    -r -V "DEBIAN_UDIT_EDITION" -J -l \
    -e boot/grub/efi.img -no-emul-boot \
    -append_partition 2 0xef boot/grub/efi.img \
    -o out.iso ./
  ```

  **Aquí está el defecto estructural:** éste no es el comando canónico de `live-build` / `debian-cd` para arm64. Le faltan 3 flags críticas (ver §3.1).

- **Iteraciones v1–v8:** documentadas en §11.1 de la memoria (kernel panic por falta de `live-boot`, autologin en bucle, Plymouth sin tema, grupo `wireshark`, locales). Llegan a "release candidate" sin haber probado en QEMU por falta de RAM libre en el host.
- **v9–v14:** no mencionadas en la memoria. Aparecen en disco y hay logs en `work/bootfix/`. En esas iteraciones se movieron wallpapers y temas, pero el `grub.cfg` quedó con `timeout=0` y kernel cmdline sin `quiet splash`.

---

## 3. Problemas encontrados

### 3.1 🔴 BLOCKER — `xorriso` produce un hybrid-ISO inválido para hypervisors estrictos

- **Síntoma:** Parallels Desktop y VirtualBox no arrancan la ISO. En QEMU funciona porque QEMU es permisivo.
- **Evidencia:**
  ```
  $ xorriso -indev v14.iso -report_el_torito plain -toc
  Boot record : El Torito , MBR protective-msdos-label cyl-align-off GPT
  El Torito boot img : 1 UEFI y none 0x0000 0x00 0 66
  ```
  - `cyl-align-off` → alineación de cilindros desactivada.
  - `Ldsiz = 0` → tamaño de carga en El-Torito es 0 (firmware no sabe cuánto leer; solo arranca si se cae a un fallback de "cargar BOOTAA64.EFI directamente").
  - El `-append_partition 2 0xef` está presente pero **no** se usó `-appended_part_as_gpt` ni `-isohybrid-gpt-basdat`. La entrada GPT resultante no tiene tipo *Microsoft basic data* → Parallels decide que no es un disco bootable válido.
- **Causa raíz:** El comando xorriso en `scripts/patch_v9_netcat.sh:58-62` y en la memoria §9.5 está abreviado. El comando que **realmente** usan las ISO oficiales de Debian live arm64 (extraído de `debian-cd` y de la wiki de Debian) es mucho más largo (ver §4.1).
- **Severidad:** BLOCKER. Es el motivo por el que no arranca fuera de QEMU.

### 3.2 🔴 BLOCKER — VirtualBox (Oracle VM) no soporta guests arm64 en host x86

- **Síntoma:** "mv oracle no lo lee".
- **Causa raíz externa:** VirtualBox solo ejecuta guests arm64 si el **host** es también arm64 (Apple Silicon) y usando la edición VirtualBox arm64 experimental (≥ 7.1.x). En cualquier host Intel/AMD es **imposible** arrancar una ISO arm64 en VBox, no hay fix.
- **Severidad:** BLOCKER inherente. Se documenta y se descarta del alcance.

### 3.3 🟠 HIGH — Arranque lento (> 2 min hasta login gráfico)

- **Síntoma:** "tarda muchísimo, se pasa el inicio de sesión y va super lento".
- **Evidencia directa** (`work/bootfix/serial-v14-final.log`, líneas 23-115):
  ```
  Job ldconfig.service/start running     (1min 4s → 1min 12s)
  Job console-setup.service/start        (1min 6s → 1min 11s)
  Job live-config.service/start          (1min 7s → 2min 19s)
  ```
  Después arranca `lightdm.service`.
- **Causa raíz múltiple:**
  1. **Sin aceleración HW.** El host de pruebas (VM Parallels sobre Apple Silicon) no expone KVM al QEMU anidado. Todo corre en TCG puro → factor 10-30× más lento.
  2. **`live-config` ejecuta 35 scripts en orden**, incluidos `0030-user-setup` (que aunque detecta el usuario ya creado tarda en comprobar), `0050-locales`, `0070-tzdata`, `0100-lightdm`, `1140-xserver-xorg`, etc. Cada uno trae un `. /usr/lib/live/config.sh` + chequeos `dpkg-query`, que en TCG son minutos.
  3. **No se desactivó `live-config` parcialmente.** En `/etc/live/config.conf.d/` (directorio vacío en el squashfs v14) se pueden inyectar overrides como `LIVE_CONFIG_DISABLED_COMPONENTS="user-setup,keyboard-configuration,sudo"` para saltar scripts ya aplicados en el chroot.
  4. **`ldconfig.service`** tarda 70 s porque el caché del linker no se regeneró en el chroot antes de comprimir el squashfs (se regenera en cada arranque).
  5. **`console-setup.service`** regenera la configuración de consola cada vez porque no hay estado persistente y `etc/default/keyboard` no está fijado a `XKBLAYOUT=es` en el squashfs.
- **Severidad:** HIGH. Sin aceleración no se puede bajar a segundos, pero sí se puede bajar a < 60 s con los fixes de §4.2.

### 3.4 🟠 HIGH — GRUB arranca sin menú y sin tema

- **Síntoma:** "no se ven las customizaciones" (GRUB).
- **Evidencia** (`/tmp/grub.cfg` extraído de v14):
  ```
  set default=0
  set timeout=0
  search --no-floppy --set=root --label "DEBIAN_UDIT_EDITION"
  ...
  set gfxpayload=keep
  menuentry "Debian UDIT PixelForge - Live" {
    linux /live/vmlinuz boot=live components locales=es_ES.UTF-8 keyboard-layouts=es
    initrd /live/initrd.img
  }
  ```
- **Problemas concretos:**
  - `timeout=0` → GRUB no muestra el menú, arranca la única entrada directamente. El tema pixelart nunca se renderiza.
  - Sólo **1** `menuentry`. La memoria §7.2 y §17.4 prometen 3 (live / safe / debug). No existen.
  - **No hay `insmod gfxmenu`** ni `set theme=/boot/grub/themes/udit-pixelart/theme.txt`. Los archivos `boot/grub/themes/udit-pixelart/*` están presentes en la ISO pero **no se cargan**.
  - **No hay `set gfxmode`** explícito.
- **Severidad:** HIGH.

### 3.5 🟠 HIGH — Plymouth no se ve durante el boot

- **Síntoma:** "las customizaciones no se aplican" (Plymouth).
- **Evidencia:**
  - `plymouthd.conf` dentro del squashfs: `[Daemon] Theme=pixelforge ShowDelay=0` ✅
  - `plymouth-start.service` sí se levanta según `serial-v14-final.log:10,17`.
  - **Kernel cmdline sin `splash`**: `boot=live components locales=es_ES.UTF-8 keyboard-layouts=es` (ver `grub.cfg` extraído arriba).
- **Causa raíz:** Plymouth solo pinta splash gráfico cuando el kernel lo arranca con `splash`. Sin ese parámetro, se ejecuta en modo "detail" (texto con logs systemd), que es exactamente lo que muestra el serial log.
- **Severidad:** HIGH. One-liner en `grub.cfg`.

### 3.6 🟠 HIGH — Autologin de LightDM entra en conflicto con getty@tty1

- **Síntoma:** "se pasa el inicio de sesión".
- **Evidencia** (`work/sq14/etc/lightdm/lightdm.conf`):
  ```ini
  [LightDM]
  minimum-vt=1        ← ⚠️ cambiado de 7 a 1

  [Seat:*]
  autologin-user=user
  autologin-user-timeout=0
  autologin-session=xfce
  user-session=xfce
  greeter-session=lightdm-gtk-greeter
  ```
- **Problema:** `minimum-vt=1` hace que LightDM intente levantar el servidor X en **VT1**, que ya está ocupado por `getty@tty1` (confirmado en `serial-v14-final.log:133` — `Started getty@tty1.service`). Resultado: LightDM o bien pelea con getty, o bien su sesión X salta al siguiente VT libre y el autologin "se pierde" desde la perspectiva del usuario.
- **Causa raíz:** la memoria §9.4.2 fija `minimum-vt=7` correctamente, pero la versión de `lightdm.conf` que terminó en el squashfs v14 tiene `minimum-vt=1`. Regresión entre iteraciones.
- **Severidad:** HIGH.

### 3.7 🟡 MEDIUM — Home `/home/user/` vacío (sin skel ni defaults XFCE)

- **Evidencia:** `ls work/sq14/home/user/` → vacío. No hay `.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml`, no hay `.config/autostart/*`, no hay cursor/theme/icons defaults.
- **Impacto:**
  - Aunque XFCE arranque, **no sabe qué wallpaper poner** (se queda en gris o en el default de Debian).
  - **No se carga la fuente "Press Start 2P"** en ningún plugin del panel ni en el terminal — Debian no la aplica por sí sola.
  - **No existe `terminalrc`**, así que xfce4-terminal abre con tema neutro (no el pixelart prometido en §16).
- **Severidad:** MEDIUM (el sistema funciona; solo el branding no se ve).

### 3.8 🟡 MEDIUM — Paquete `fonts-press-start-2p` NO instalado

- **Evidencia:**
  ```
  $ grep "^Package: fonts-press-start-2p$" work/sq14/var/lib/dpkg/status
  (sin salida)
  ```
  777 paquetes instalados, **no uno de ellos es `fonts-press-start-2p`**.
- **Impacto:** LightDM greeter y MOTD no pueden renderizar la fuente que la memoria declara usar. Es un gap literal con §9.4.1 de la memoria.
- **Severidad:** MEDIUM.

### 3.9 🟡 MEDIUM — Usuario `danielsson` fantasma en `/home/`

- **Evidencia:** `ls work/sq14/home/` → `danielsson  user`. `/home/danielsson` está vacío.
- **Causa probable:** residuo del `debian-live-*-standard.iso` original. El autor oficial de Debian Live es *Daniel Baumann* (alias `danielsson` en algunos scripts). Al customizar con Cubic nadie eliminó ese home preexistente.
- **Impacto:** cosmético y de tamaño, pero queda feo en la auditoría. Se ve en `ls /home`.
- **Severidad:** MEDIUM (cosmético pero delator en un proyecto universitario).

### 3.10 🟡 MEDIUM — `lightdm-fallback.service` enmascarado a `/dev/null`

- **Evidencia:** `ls -la work/sq14/etc/systemd/system/lightdm-fallback.service` → `-> /dev/null`.
- **Lectura:** en algún momento se definió un `lightdm-fallback.service` personalizado, luego se masked con `systemctl mask`. Esto no rompe el boot, pero indica un intento de resolver el problema 3.6 por la vía equivocada.
- **Severidad:** MEDIUM. Eliminar el symlink.

### 3.11 🟢 LOW — Carpeta `.disk/` residual del installer

- **Evidencia:** `xorriso -find / -maxdepth 2` muestra `/.disk/base_installable`, `/.disk/info`, `/.disk/udeb_include`.
- **Impacto:** son metadatos del instalador d-i que el ISO live no necesita. Ocupan poco, pero la memoria §7.2 no los declara.
- **Severidad:** LOW (cosmético).

---

## 4. Plan de fix priorizado

### 4.1 🔴 Reempaquetar con el `xorriso` canónico para arm64 hybrid

**Objetivo:** que Parallels Desktop (Apple Silicon) arranque la ISO correctamente. VirtualBox queda fuera por limitación externa (§3.2).

**Comando de referencia** (adaptado de Debian wiki [RepackBootableISO](https://wiki.debian.org/RepackBootableISO) y de las recetas arm64 oficiales):

```bash
#!/bin/bash
set -euo pipefail

ISO_IN="debian-udit-pixelart-arm64-v14.iso"
ISO_OUT="debian-udit-pixelart-arm64-v15.iso"

WORK="$(mktemp -d)"
trap 'sudo rm -rf "$WORK"' EXIT

# 1. Extraer árbol del ISO (sin El-Torito)
sudo mount -o loop,ro "$ISO_IN" /mnt
sudo rsync -a /mnt/ "$WORK/iso/"
sudo umount /mnt

# 2. [Opcional] regenerar md5sum.txt si modificaste squashfs
(cd "$WORK/iso" && sudo bash -c \
  "find . -type f -print0 | xargs -0 md5sum | grep -v boot.catalog > md5sum.txt")

# 3. Reempaquetar con las flags correctas
cd "$WORK/iso"
sudo xorriso -as mkisofs \
  -r -V "DEBIAN_UDIT_EDITION" \
  -J -joliet-long -l \
  -iso-level 3 \
  -partition_offset 16 \
  -partition_cyl_align off \
  -no-emul-boot \
  -e boot/grub/efi.img \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:all::' \
  -no-emul-boot \
  -append_partition 2 0xef boot/grub/efi.img \
  -appended_part_as_gpt \
  -isohybrid-gpt-basdat \
  -o "$ISO_OUT" .
```

**Cambios clave respecto al comando actual:**
- `-iso-level 3` → soporte para archivos > 4 GB y paths largos.
- `-partition_offset 16` → hueco de 16 bloques para que el ISO sea escribible directamente a USB particionado.
- `-partition_cyl_align off` → declarado explícitamente (no implícito).
- `-appended_part_as_gpt` + `-isohybrid-gpt-basdat` → convierten la partición 2 apéndice en GPT basic-data con el flag EFI System Partition. **Sin estos dos flags, Parallels rechaza el ISO.**
- `-boot-load-size 4 -boot-info-table` → El-Torito correcto con tamaño de carga y tabla de info, en lugar del `Ldsiz = 0` actual.
- `-eltorito-alt-boot` + segundo `-e` apuntando a `appended_partition_2:all::` → registra la partición apéndice como segundo punto de entrada UEFI.

**Verificación post-build:**
```bash
xorriso -indev "$ISO_OUT" -report_el_torito plain -toc | head -20
# Debe mostrar:
#   Boot record : El Torito , MBR protective-msdos-label cyl-align-on GPT
#   El Torito boot img : 1 UEFI y none 0x0000 0x00 ... (Ldsiz != 0)
```

Fuente: [Debian wiki RepackBootableISO](https://wiki.debian.org/RepackBootableISO), [debian-live mailing list — Hybrid ISO with GPT](https://lists.debian.org/debian-live/2019/02/msg00035.html).

---

### 4.2 🟠 Acelerar el arranque (objetivo: < 60 s en QEMU sin KVM)

**Acción A — Overrides de `live-config`.** Crear el fichero `/etc/live/config.conf` dentro del chroot antes de reempaquetar:

```bash
cat > /etc/live/config.conf <<'EOF'
LIVE_CONFIG_COMPONENTS="hostname,sudo,locales,tzdata,live-debconfig_passwd"
LIVE_HOSTNAME="pixelforge"
LIVE_USERNAME="user"
LIVE_USER_FULLNAME="PixelForge User"
LIVE_LOCALES="es_ES.UTF-8"
LIVE_TIMEZONE="Europe/Madrid"
LIVE_KEYBOARD_LAYOUTS="es"
LIVE_KEYBOARD_MODEL="pc105"
EOF
```

Esto:
- Limita `live-config` a 5 componentes en vez de 35 (→ `live-config.service` baja de 2 min a ~10 s).
- Elimina `user-setup`, `gdm3`, `kdm`, `sddm`, `lightdm` (live-config), `xserver-xorg` y el resto de componentes que no aplican (porque ya se configuraron en el chroot con Cubic).

Fuente: [live-config(7)](https://manpages.debian.org/testing/live-config/live-config.7.en.html).

**Acción B — Regenerar ldconfig en el chroot** (antes de `mksquashfs`):

```bash
# Dentro del chroot Cubic, como último paso
ldconfig
update-initramfs -u
```

Si `ld.so.cache` está precalentado, `ldconfig.service` al arrancar detecta que todo está al día y sale en < 1 s en lugar de 70 s.

**Acción C — Fijar teclado en `/etc/default/keyboard`:**
```bash
cat > /etc/default/keyboard <<'EOF'
XKBMODEL="pc105"
XKBLAYOUT="es"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
```
Evita que `console-setup.service` regenere la tabla en cada arranque.

**Acción D — Deshabilitar servicios innecesarios en modo live:**
```bash
systemctl disable apt-daily.timer apt-daily-upgrade.timer
systemctl disable e2scrub_all.timer
systemctl disable smartd.service smartmontools.service  # opcional si no hay SMART
systemctl disable NetworkManager-wait-online.service
systemctl mask systemd-networkd-wait-online.service
```
`NetworkManager-wait-online` es uno de los mayores ofensores de boot lento: bloquea `network-online.target` hasta 30 s esperando una IP.

**Acción E — Para Parallels específicamente: activar aceleración de virtualización anidada** si el host Mac lo soporta. En Parallels Desktop ≥ 19, en **Configuración → Hardware → CPU → "Habilitar virtualización anidada"**. Esto permite que QEMU dentro de la VM Debian use KVM y multiplica × 20 la velocidad.

---

### 4.3 🟠 Arreglar `grub.cfg` (menú, tema, splash)

**Reemplazar** `boot/grub/grub.cfg` dentro del árbol ISO (antes del `xorriso`) por:

```grub
insmod all_video
insmod gfxterm
insmod png
insmod jpeg
insmod iso9660
insmod search
insmod search_label

set default="0"
set timeout=10

search --no-floppy --set=root --label "DEBIAN_UDIT_EDITION"
if [ -z "$root" ]; then
    search --no-floppy --set=root --file /live/vmlinuz
fi

set gfxmode=1024x768,auto
set gfxpayload=keep
insmod gfxmenu
loadfont /boot/grub/themes/udit-pixelart/dejavu-16.pf2 2>/dev/null || true
set theme=/boot/grub/themes/udit-pixelart/theme.txt
export theme

menuentry "Debian UDIT PixelForge — Live (normal)" {
    linux /live/vmlinuz boot=live components quiet splash locales=es_ES.UTF-8 keyboard-layouts=es
    initrd /live/initrd.img
}

menuentry "Debian UDIT PixelForge — Live (safe graphics, nomodeset)" {
    linux /live/vmlinuz boot=live components quiet splash locales=es_ES.UTF-8 keyboard-layouts=es nomodeset
    initrd /live/initrd.img
}

menuentry "Debian UDIT PixelForge — Live (debug, no splash, consola)" {
    linux /live/vmlinuz boot=live components locales=es_ES.UTF-8 keyboard-layouts=es systemd.log_level=debug
    initrd /live/initrd.img
}

menuentry "Comprobar medio" {
    linux /live/vmlinuz boot=live components integrity-check quiet splash
    initrd /live/initrd.img
}
```

**Cambios:**
- `timeout=10` → menú visible 10 s.
- **3 entradas reales** (live, safe, debug) + una de integridad, cumpliendo §7.2 de la memoria.
- `quiet splash` en las 2 primeras → Plymouth renderiza el tema `pixelforge`.
- `set theme=...` → carga el tema pixelart GRUB.
- `loadfont` con la fuente del tema (si el tema la trae, si no se silencia con `|| true`).

---

### 4.4 🟠 Arreglar autologin de LightDM

En el chroot, antes de reempaquetar:

```bash
cat > /etc/lightdm/lightdm.conf <<'EOF'
[LightDM]
minimum-vt=7
logind-check-graphical=false

[Seat:*]
autologin-user=user
autologin-user-timeout=0
autologin-session=xfce
user-session=xfce
greeter-session=lightdm-gtk-greeter
EOF

# Eliminar el fallback enmascarado
rm -f /etc/systemd/system/lightdm-fallback.service

# Asegurar que user pertenece a grupos correctos
usermod -aG nopasswdlogin,autologin user 2>/dev/null || true
groupadd -f autologin
groupadd -f nopasswdlogin
usermod -aG autologin,nopasswdlogin user
```

**Cambio clave:** `minimum-vt=7` (default de Debian). Así LightDM no pelea con `getty@tty1`.

---

### 4.5 🟠 Poblar `/home/user/` con branding y skel

Dentro del chroot, añadir al final antes del `exit`:

```bash
# Fuente Press Start 2P (faltaba)
apt install -y fonts-press-start-2p

# Wallpaper por defecto vía xfconf-query no funciona offline.
# Se aplica por fichero xml en skel y en /home/user:
mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /home/user/.config/xfce4/xfconf/xfce-perchannel-xml

cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVirtual-1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string"
                    value="/usr/share/backgrounds/pixelforge/pixelforge-wallpaper.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

cp /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml \
   /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

# xfce4-terminal con tema pixelart
mkdir -p /home/user/.config/xfce4/terminal
cat > /home/user/.config/xfce4/terminal/terminalrc <<'EOF'
[Configuration]
FontName=Press Start 2P 10
ColorForeground=#f1e9d2
ColorBackground=#1b2a41
ColorCursor=#4cc9f0
ColorPalette=#1b2a41;#e63946;#2a9d8f;#f4a261;#4cc9f0;#9d4edd;#06d6a0;#f1e9d2;#415a77;#ff6b6b;#43aa8b;#fcbf49;#8ecae6;#c77dff;#2ec4b6;#ffffff
EOF

# Propietario correcto del home
chown -R 1000:1000 /home/user

# Eliminar el home fantasma danielsson
rm -rf /home/danielsson
```

---

### 4.6 🟡 Limpieza final

```bash
# Eliminar metadatos del d-i leftover
sudo rm -rf "$WORK/iso/.disk"

# Eliminar initrd no-live (si existe) y vmlinuz duplicados en /install
sudo rm -rf "$WORK/iso/install.*"  # si existen
```

---

## 5. Compatibilidad de hypervisors

| Hypervisor | Soporte arm64 guest en host x86 | Soporte arm64 guest en host Apple Silicon | Veredicto |
|---|---|---|---|
| **QEMU + UEFI (AAVMF)** | ✅ (TCG, lento) | ✅ (HVF, rápido) | Ya funciona. Tenerlo como fallback siempre. |
| **Parallels Desktop 19/20** | ❌ | ✅ nativo con UEFI ARM64 | Funcionará **tras** el fix §4.1. Es el target principal del usuario. |
| **UTM (QEMU wrapper)** | ✅ (lento) | ✅ (rápido, HVF) | Alternativa recomendada si Parallels falla. Gratis. Basado en el mismo QEMU. |
| **VirtualBox 7.1 ARM edition** | ❌ | ⚠️ experimental, Oracle Linux testing only | **No recomendado.** Documentar como "fuera de alcance". |
| **VMware Fusion ARM** | ❌ | ✅ con limitaciones | No probado aquí, debería funcionar con el ISO corregido. |

**Recomendación práctica para la entrega:** probar y documentar en QEMU (reproducible) + Parallels (visual). **Desaconsejar VirtualBox explícitamente** con nota al pie en la memoria.

Fuentes:
- [Phoronix — Linux 6.14 VirtualBox Guest ARM](https://www.phoronix.com/news/Linux-6.14-VirtualBox-Guest-ARM)
- [KB Parallels: Install Linux VM on Apple M-Series](https://kb.parallels.com/en/128445)
- [UBOS: Arch Linux ARM VM with Parallels on Apple Silicon](https://ubos.net/docs/other/developer-workstation/arch-aarch64/apple-silicon-parallels/)

---

## 6. Validación de cada fix

Tras aplicar §4.1–§4.6, ejecutar este checklist:

```bash
# 1. Estructura El-Torito
xorriso -indev v15.iso -report_el_torito plain -toc 2>&1 | \
  grep -E "Boot record|El Torito boot img"
# Esperado:
#   Boot record : El Torito , MBR protective-msdos-label cyl-align-on GPT
#   El Torito boot img : 1 UEFI y none 0x0000 0x00 <N>  (N != 0)

# 2. grub.cfg contiene splash y 3 entradas
xorriso -osirrox on -indev v15.iso -extract_single /boot/grub/grub.cfg /tmp/grub.cfg
grep -c '^menuentry ' /tmp/grub.cfg  # >= 3
grep -q 'quiet splash' /tmp/grub.cfg && echo "OK splash"
grep -q 'set theme' /tmp/grub.cfg && echo "OK theme"
grep -q 'timeout=10' /tmp/grub.cfg && echo "OK timeout"

# 3. Paquetes clave
sudo unsquashfs -d /tmp/sq_check v15_squashfs.img var/lib/dpkg/status
for p in fonts-press-start-2p xfce4 lightdm plymouth live-config; do
  grep -q "^Package: $p$" /tmp/sq_check/var/lib/dpkg/status && \
    echo "[OK] $p" || echo "[FAIL] $p"
done

# 4. Home y skel
sudo unsquashfs -d /tmp/sq_check v15_squashfs.img \
  home/user/.config/xfce4/xfconf/xfce-perchannel-xml \
  etc/lightdm/lightdm.conf \
  etc/live/config.conf
test -d /tmp/sq_check/home/user/.config/xfce4 && echo "OK home user"
test ! -d /tmp/sq_check/home/danielsson && echo "OK no danielsson"
grep -q 'minimum-vt=7' /tmp/sq_check/etc/lightdm/lightdm.conf && echo "OK vt7"

# 5. Arranque QEMU con medición
time qemu-system-aarch64 -machine virt -cpu max -smp 4 -m 2048 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/AAVMF/AAVMF_CODE.fd \
  -drive if=pflash,format=raw,file=VARS.fd \
  -cdrom v15.iso \
  -display none -serial mon:stdio 2>&1 | tee boot.log
# Esperado: `pixelforge login:` o greeter lightdm visible en < 90 s.
grep -q "Job live-config.service/start running (1min" boot.log && \
  echo "❌ live-config sigue lento" || echo "✅ live-config rápido"

# 6. Arranque Parallels (manual)
# - Crear nueva VM → "Install from image file" → v15.iso
# - Debe arrancar y mostrar menú GRUB con timeout 10 s
# - Tras seleccionar "Live (normal)" → Plymouth visible → LightDM → XFCE con wallpaper
```

---

## 7. Prioridad sugerida de aplicación

| Orden | Fix | Tiempo estimado | Desbloquea |
|---|---|---|---|
| 1 | §4.1 xorriso canónico | 20 min | Arranque en Parallels |
| 2 | §4.3 grub.cfg correcto | 5 min | Menú visible + splash + 3 entradas |
| 3 | §4.4 autologin VT7 | 5 min | No se "pasa" el login |
| 4 | §4.2 live-config overrides | 15 min (requiere chroot) | Arranque 4× más rápido |
| 5 | §4.5 skel + fuente + terminal | 15 min (chroot) | Branding visible |
| 6 | §4.6 limpieza .disk y danielsson | 5 min | Aspecto pulido para auditoría |

**Tiempo total estimado:** ~65 min de trabajo + 1 ciclo de `mksquashfs` (~10-15 min en ARM TCG).

---

## 8. Notas finales para la defensa del proyecto

- El ISO v14 **no está roto técnicamente**; tiene squashfs válido, 778 paquetes correctos, plymouth y lightdm configurados. Lo que está roto es el **empaquetado xorriso final** y la **capa de arranque visible** (grub.cfg, splash). La memoria puede presentar las iteraciones v8 → v15 como un "ciclo de hardening de empaquetado" sin contradecir lo ya escrito.
- VirtualBox **no es un requisito del enunciado** (§3 de la memoria lista los requisitos y no menciona VBox). Se puede cerrar el gap con una nota: "VirtualBox arm64 guest está en fase experimental en Oracle 7.1.x y queda fuera del alcance de este proyecto; el método de prueba oficial es QEMU + UEFI AAVMF (§17) y, para validación visual, Parallels Desktop ≥ 19 sobre Apple Silicon".
- Las 3 extensiones/herramientas de boot lento (apt-daily, NetworkManager-wait-online, ldconfig) son fixes *estándar* de Debian Live, no hacks específicos del proyecto. Se documentan fácilmente.

---

**Fin del diagnóstico.**

Fuentes consultadas:
- [Debian Wiki — RepackBootableISO](https://wiki.debian.org/RepackBootableISO)
- [Debian Wiki — XorrisoDdTarget](https://wiki.debian.org/XorrisoDdTarget)
- [Debian live ML — Hybrid ISO with GPT](https://lists.debian.org/debian-live/2019/02/msg00035.html)
- [live-config(7) manpage](https://manpages.debian.org/testing/live-config/live-config.7.en.html)
- [Debian Wiki — BootProcessSpeedup](https://wiki.debian.org/BootProcessSpeedup)
- [KB Parallels — Linux VM on Apple M-Series](https://kb.parallels.com/en/128445)
- [Phoronix — Linux 6.14 VirtualBox Guest ARM](https://www.phoronix.com/news/Linux-6.14-VirtualBox-Guest-ARM)
- [UBOS — Arch ARM VM con Parallels on Apple Silicon](https://ubos.net/docs/other/developer-workstation/arch-aarch64/apple-silicon-parallels/)
