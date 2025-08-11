#!/bin/sh
# /etc/uci-defaults/99-hg680pctl.sh
# Autostart LED mode + Netwatch untuk HG680P

echo "[INFO] Mengatur hg680pctl..."

# Pastikan file hg680pctl ada
if [ -f /usr/bin/hg680pctl ]; then
    chmod +x /usr/bin/hg680pctl

    # Autostart di rc.local
    if ! grep -q '/usr/bin/hg680pctl power heart' /etc/rc.local; then
        sed -i '/exit 0/i \/usr\/bin\/hg680pctl power heart &' /etc/rc.local
    fi
    if ! grep -q '/usr/bin/hg680pctl lan disko' /etc/rc.local; then
        sed -i '/exit 0/i \/usr\/bin\/hg680pctl lan disko &' /etc/rc.local
    fi

    # Buat script netwatch
    NETWATCH_SCRIPT="/etc/netwatch/hg680pctl.sh"
    mkdir -p /etc/netwatch

    cat > "$NETWATCH_SCRIPT" <<'EOF'
#!/bin/sh
PING_TARGET="bing.com"

if ping -c 1 -W 2 "$PING_TARGET" >/dev/null 2>&1; then
    /usr/bin/hg680pctl power heart
    /usr/bin/hg680pctl lan disko
else
    /usr/bin/hg680pctl power off
    /usr/bin/hg680pctl lan off
fi
EOF
    chmod +x "$NETWATCH_SCRIPT"

    # Tambahkan cron untuk cek setiap menit (bukan 30 detik)
    if ! crontab -l | grep -q "$NETWATCH_SCRIPT"; then
        (crontab -l 2>/dev/null; echo "*/1 * * * * $NETWATCH_SCRIPT") | crontab -
    fi
    
    /etc/init.d/cron enable
    /etc/init.d/cron restart

else
    echo "[WARN] /usr/bin/hg680pctl tidak ditemukan, skip autostart & netwatch" >&2
fi

# Hapus diri setelah dijalankan
rm -f "$0"