#!/bin/bash
# /etc/profile.d/robosec-banner.sh
# Banner de inicio - PixelForge v20
# Solo se muestra en TTY interactivas, no en sesiones SSH ni X

case "$(tty)" in
    /dev/tty[0-9]*)
        # lolcat se instala en /usr/games en Debian; fallback explicito
        LOLCAT=""
        for cand in /usr/games/lolcat /usr/bin/lolcat /usr/local/bin/lolcat; do
            [ -x "$cand" ] && LOLCAT="$cand" && break
        done
        if command -v figlet >/dev/null 2>&1; then
            if [ -n "$LOLCAT" ]; then
                figlet -f slant "PixelForge" | "$LOLCAT" -f 2>/dev/null || figlet -f slant "PixelForge"
            else
                figlet -f slant "PixelForge"
            fi
        else
            echo "=== PixelForge v20 ==="
        fi
        echo ""
        echo "  Kernel  : $(uname -r)"
        echo "  IP      : $(hostname -I 2>/dev/null | awk '{print $1}')"
        echo "  Usuario : $(whoami)"
        echo "  Uptime  : $(uptime -p 2>/dev/null)"
        echo ""
        echo "  Lanza el menu interactivo: robomenu"
        echo ""
        ;;
esac
