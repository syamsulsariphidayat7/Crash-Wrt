#!/bin/sh

# Setup logging
LOG_FILE="/root/setup-crashwrt.log"
exec > "$LOG_FILE" 2>&1

# logging dengan status
log_status() {
    local status="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$status" in
        "INFO")
            echo "[$timestamp] [INFO] $message"
            ;;
        "SUCCESS")
            echo "[$timestamp] [SUCCESS] ✓ $message"
            ;;
        "ERROR")
            echo "[$timestamp] [ERROR] ✗ $message"
            ;;
        "WARNING")
            echo "[$timestamp] [WARNING] ⚠ $message"
            ;;
        *)
            echo "[$timestamp] $message"
            ;;
    esac
}

# header log
log_status "INFO" "========================================="
log_status "INFO" "Crash-Wrt Setup Script Started"
log_status "INFO" "Script Setup By Crashoverride"
log_status "INFO" "Installed Time: $(date '+%A, %d %B %Y %T')"
log_status "INFO" "========================================="

# modify firmware display
log_status "INFO" "Modifying firmware display..."
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' By Crashoverride':''),#g" /www/luci-static/resources/view/status/include/10_system.js 2>/dev/null

# change icon port
sed -i -E 's/icons\/port_%s\.(svg|png)/icons\/port_%s.gif/g' /www/luci-static/resources/view/status/include/29_ports.js 2>/dev/null
mv /www/luci-static/resources/view/status/include/29_ports.js /www/luci-static/resources/view/status/include/11_ports.js 2>/dev/null
log_status "SUCCESS" "Firmware and port modifications completed"

# check system release
log_status "INFO" "Checking system release..."
if grep -q "ImmortalWrt" /etc/openwrt_release 2>/dev/null; then
    log_status "INFO" "ImmortalWrt detected"
    sed -i 's/\(DISTRIB_DESCRIPTION='\''ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' /etc/openwrt_release 2>/dev/null
    sed -i 's|system/ttyd|services/ttyd|g' /usr/share/luci/menu.d/luci-app-ttyd.json 2>/dev/null
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release 2>/dev/null | awk -F"'" '{print $2}')
    log_status "INFO" "Branch version: $BRANCH_VERSION"
elif grep -q "OpenWrt" /etc/openwrt_release 2>/dev/null; then
    log_status "INFO" "OpenWrt detected"
    sed -i 's/\(DISTRIB_DESCRIPTION='\''OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' /etc/openwrt_release 2>/dev/null
    mv /www/luci-static/resources/view/status/include/27_temperature.js /www/luci-static/resources/view/status/include/15_temperature.js 2>/dev/null
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release 2>/dev/null | awk -F"'" '{print $2}')
    log_status "INFO" "Branch version: $BRANCH_VERSION"
else
    log_status "WARNING" "Unknown system release"
fi

log_status "INFO" "Setting up root password..."
(echo "crash"; sleep 2; echo "crash") | passwd >/dev/null 2>&1
log_status "SUCCESS" "Root password configured"

# setup hostname and timezone
log_status "INFO" "Configuring hostname and timezone to Asia/Jakarta..."
uci set system.@system[0].hostname='Crash-Wrt' 2>/dev/null
uci set system.@system[0].timezone='WIB-7' 2>/dev/null
uci set system.@system[0].zonename='Asia/Jakarta' 2>/dev/null
uci delete system.ntp.server 2>/dev/null
uci add_list system.ntp.server='pool.ntp.org' 2>/dev/null
uci add_list system.ntp.server='id.pool.ntp.org' 2>/dev/null
uci add_list system.ntp.server='time.google.com' 2>/dev/null
uci commit system 2>/dev/null
log_status "SUCCESS" "System configuration completed"

# setup bahasa default
log_status "INFO" "Setting up default language to English..."
uci set luci.@core[0].lang='en' 2>/dev/null
uci commit luci 2>/dev/null
log_status "SUCCESS" "Language set to English"

# configure wan and lan
log_status "INFO" "Configuring WAN and LAN interfaces..."
uci delete network.wan6 2>/dev/null
uci commit network 2>/dev/null
log_status "SUCCESS" "Network configuration completed"

log_status "INFO" "Configuring firewall..."
uci set firewall.@zone[1].network='WAN1' 2>/dev/null
uci commit firewall 2>/dev/null
log_status "SUCCESS" "Firewall configuration completed"

# disable ipv6 lan
log_status "INFO" "Disabling IPv6 on LAN..."
uci delete dhcp.lan.dhcpv6 2>/dev/null
uci delete dhcp.lan.ra 2>/dev/null
uci delete dhcp.lan.ndp 2>/dev/null
uci commit dhcp 2>/dev/null
log_status "SUCCESS" "IPv6 disabled on LAN"

# configure wireless device
log_status "INFO" "Configuring wireless devices..."
uci set wireless.@wifi-device[0].disabled='0' 2>/dev/null
uci set wireless.@wifi-iface[0].disabled='0' 2>/dev/null
uci set wireless.@wifi-iface[0].mode='ap' 2>/dev/null
uci set wireless.@wifi-iface[0].encryption='psk2' 2>/dev/null
uci set wireless.@wifi-iface[0].key='crash' 2>/dev/null
uci set wireless.@wifi-device[0].country='ID' 2>/dev/null

# check for Raspberry Pi Devices
if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo 2>/dev/null; then
    log_status "INFO" "Raspberry Pi 3/4 detected, configuring 5GHz WiFi..."
    uci set wireless.@wifi-iface[0].ssid='Crash-Wrt_5G' 2>/dev/null
    uci set wireless.@wifi-device[0].channel='149' 2>/dev/null
    uci set wireless.@wifi-device[0].htmode='VHT80' 2>/dev/null
else
    uci set wireless.@wifi-iface[0].ssid='Crash-Wrt' 2>/dev/null
    uci set wireless.@wifi-device[0].channel='1' 2>/dev/null
    uci set wireless.@wifi-device[0].htmode='HT20' 2>/dev/null
    log_status "INFO" "Standard WiFi configuration applied"
fi

uci commit wireless 2>/dev/null
wifi reload >/dev/null 2>&1
wifi up >/dev/null 2>&1
log_status "SUCCESS" "Wireless configuration completed"

# check wireless interface
if iw dev 2>/dev/null | grep -q Interface; then
    log_status "SUCCESS" "Wireless interface detected"
    if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo 2>/dev/null; then
        if ! grep -q "wifi up" /etc/rc.local 2>/dev/null; then
            sed -i '/exit 0/i # remove if you dont use wireless' /etc/rc.local 2>/dev/null
            sed -i '/exit 0/i sleep 10 && wifi up' /etc/rc.local 2>/dev/null
        fi
        if ! grep -q "wifi up" /etc/crontabs/root 2>/dev/null; then
            echo "# remove if you dont use wireless" >> /etc/crontabs/root 2>/dev/null
            echo "0 */12 * * * wifi down && sleep 5 && wifi up" >> /etc/crontabs/root 2>/dev/null
            /etc/init.d/cron restart >/dev/null 2>&1
        fi
    fi
else
    log_status "WARNING" "No wireless device detected"
fi

# remove huawei me909s and dw5821e usb-modeswitch
log_status "INFO" "Removing Huawei ME909S and DW5821E USB modeswitch entries..."
sed -i -e '/12d1:15c1/,+5d' -e '/413c:81d7/,+5d' /etc/usb-mode.json 2>/dev/null
log_status "SUCCESS" "USB modeswitch entries removed"

# disable xmm-modem
log_status "INFO" "Disabling XMM-Modem using UCI"
uci set xmm-modem.@xmm-modem[0].enable='0' 2>/dev/null
uci commit xmm-modem 2>/dev/null
log_status "SUCCESS" "XMM-Modem disabled"

# disable opkg signature check
log_status "INFO" "Disabling OPKG signature check..."
sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf 2>/dev/null
log_status "SUCCESS" "OPKG signature check disabled"

# add custom repository
log_status "INFO" "Adding custom repository..."
ARCH=$(grep "OPENWRT_ARCH" /etc/os-release 2>/dev/null | awk -F '"' '{print $2}')
if [ -n "$ARCH" ]; then
    echo "src/gz custom_packages https://dl.openwrt.ai/latest/packages/$ARCH/kiddin9" >> /etc/opkg/customfeeds.conf 2>/dev/null
    log_status "SUCCESS" "Custom repository added for architecture: $ARCH"
else
    log_status "WARNING" "Could not determine architecture for custom repository"
fi

# setup default theme
log_status "INFO" "Setting up alpha theme as default..."
uci set luci.main.mediaurlbase='/luci-static/alpha' 2>/dev/null
uci commit luci 2>/dev/null
log_status "SUCCESS" "alpha theme set as default"

# remove login password ttyd
log_status "INFO" "Configuring TTYD without login password..."
uci set ttyd.@ttyd[0].command='/bin/bash --login' 2>/dev/null
uci commit ttyd 2>/dev/null
log_status "SUCCESS" "TTYD configuration completed"

# symlink Tinyfm
log_status "INFO" "Creating TinyFM symlink..."
ln -sf / /www/tinyfm/rootfs 2>/dev/null
log_status "SUCCESS" "TinyFM rootfs symlink created"

# setup misc settings
log_status "INFO" "Setting up misc settings and permissions..."
sed -i -e 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' -e 's/\[ -n \"\$FAILSAFE\" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/foundx/' /etc/profile 2>/dev/null
chmod -R +x /sbin /usr/bin 2>/dev/null
# chmod +x /etc/init.d/vnstat_backup 2>/dev/null
chmod +x /etc/init.d/issue 2>/dev/null
chmod +x /usr/lib/ModemManager/connection.d/10-report-down 2>/dev/null
chmod +x /www/cgi-bin/reset-vnstat.sh /www/vnstati/vnstati.sh 2>/dev/null
chmod 600 /etc/vnstat.conf 2>/dev/null

# issue not booting
log_status "INFO" "Adding and running install2 script..."
if [ -f "/root/install2.sh" ]; then
    chmod +x /root/install2.sh 2>/dev/null
    if /root/install2.sh; then
        log_status "SUCCESS" "install2 script executed successfully"
    else
        log_status "ERROR" "Failed to execute install2 script"
    fi
else
    log_status "WARNING" "install2.sh not found, skipping configuration"
fi

log_status "SUCCESS" "Misc settings configured"

# add auto sinkron jam, Clean Cache, Remove mm tty
log_status "INFO" "Add Auto Sinkron Jam, Clean Cache, Remove mm tty..."
sed -i '/exit 0/i #sh /usr/bin/autojam.sh bug.com' /etc/rc.local 2>/dev/null
rm -f /etc/hotplug.d/tty/25-modemmanager-tty 2>/dev/null
log_status "SUCCESS" "Auto sync, cache settings, remove mm tty applied"

# setup device amlogic
# /etc/uci-defaults/99-hg680pctl.sh
# Autostart LED mode + Netwatch untuk HG680P

log_status "INFO" "Checking for Amlogic device configuration..."
if opkg list-installed 2>/dev/null | grep -q luci-app-amlogic; then
    log_status "INFO" "luci-app-amlogic detected"
    rm -f /etc/profile.d/30-sysinfo.sh 2>/dev/null
    
log_status "[INFO] Mengatur hg680pctl..."

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
        (crontab -l 2>/dev/null; log_status "*/1 * * * * $NETWATCH_SCRIPT") | crontab -
    fi
    
    /etc/init.d/cron enable
    /etc/init.d/cron restart

else
    log_status "[WARN] /usr/bin/hg680pctl tidak ditemukan, skip autostart & netwatch" >&2
fi
else
    log_status "INFO" "luci-app-amlogic not detected"
    rm -f '/exit 0/i \/usr\/bin\/hg680pctl power heart &' /etc/rc.local
    rm -f '/exit 0/i \/usr\/bin\/hg680pctl lan disko &' /etc/rc.local
fi

# add TTL
log_status "INFO" "Adding and running TTL script..."
if [ -f /root/indowrt.sh ]; then
    chmod +x /root/indowrt.sh 2>/dev/null
    /root/indowrt.sh
    log_status "SUCCESS" "TTL script executed"
else
    log_status "WARNING" "indowrt.sh not found, skipping TTL configuration"
fi

# nikki-x
log_status "INFO" "Adding and running Nikki-x script..."
if [ -f /root/nikki-x.sh ]; then
    chmod +x /root/nikki-x.sh 2>/dev/null
    /root/nikki-x.sh
    log_status "SUCCESS" "Nikki-x script executed"
else
    log_status "WARNING" "Nikki-x.sh not found, skipping Nikki configuration"
fi

# add rules
log_status "INFO" "Adding and running rules script..."
if [ -f /root/rules.sh ]; then
    chmod +x /root/rules.sh 2>/dev/null
    /root/rules.sh
    log_status "SUCCESS" "Rules script executed"
else
    log_status "WARNING" "rules.sh not found, skipping Rules configuration"
fi

# mv_safe
log_status "INFO" "Mv safe configuration..."
if [ -f /root/mv_safe.sh ]; then
    chmod +x /root/mv_safe.sh 2>/dev/null
    /root/mv_safe.sh
    log_status "SUCCESS" "mv_safe configuration script executed"
else
    log_status "WARNING" "mv_safe.sh not found, skipping mv_safe configuration"
fi

# move jquery.min.js
log_status "INFO" "Moving jQuery library..."
mv /usr/share/netdata/web/lib/jquery-3.6.0.min.js /usr/share/netdata/web/lib/jquery-2.2.4.min.js 2>/dev/null
log_status "SUCCESS" "jQuery library version changed"

# create directory vnstat
log_status "INFO" "Creating VnStat directory..."
mkdir -p /etc/vnstat 2>/dev/null
log_status "SUCCESS" "VnStat directory created"

# restart netdata and vnstat
log_status "INFO" "Restarting Netdata and VnStat services..."
/etc/init.d/netdata restart >/dev/null 2>&1
/etc/init.d/vnstat restart >/dev/null 2>&1
log_status "SUCCESS" "Services restarted"

# run vnstati.sh
log_status "INFO" "Running VnStati script..."
/www/vnstati/vnstati.sh >/dev/null 2>&1
log_status "SUCCESS" "VnStati script executed"

# setup enable services
log_status "INFO" "Enable Services.."
# /etc/init.d/vnstat_backup enable >/dev/null 2>&1
/etc/init.d/issue enable >/dev/null 2>&1
log_status "SUCCESS" "Services enabled"

# setup tunnel installed
log_status "INFO" "Checking for tunnel applications..."
for pkg in luci-app-openclash luci-app-nikki luci-app-passwall; do
    if opkg list-installed 2>/dev/null | grep -qw "$pkg"; then
        log_status "INFO" "$pkg detected"
        case "$pkg" in
            luci-app-openclash)
                chmod +x /etc/openclash/core/clash_meta 2>/dev/null
                chmod +x /etc/openclash/Country.mmdb 2>/dev/null
                chmod +x /etc/openclash/Geo* 2>/dev/null
                chmod -R +x /usr/share/openclash 2>/dev/null
                
                log_status "INFO" "Patching OpenClash overview..."
                if [ -f /usr/bin/ocpatch.sh ]; then
                    bash /usr/bin/ocpatch.sh >/dev/null 2>&1
                    log_status "SUCCESS" "OpenClash overview patched"
                else
                    log_status "WARNING" "ocpatch.sh not found"
                fi
                
                ln -sf /etc/openclash/history/CrashWrt.db /etc/openclash/cache.db 2>/dev/null
                ln -sf /etc/openclash/core/clash_meta /etc/openclash/clash 2>/dev/null
                rm -f /etc/config/openclash 2>/dev/null
                rm -rf /etc/openclash/custom /etc/openclash/game_rules 2>/dev/null
                find /etc/openclash/rule_provider -type f ! -name '*.yaml' -exec rm -f {} \; 2>/dev/null
                mv /etc/config/openclash1 /etc/config/openclash 2>/dev/null
                ;;
            luci-app-nikki)
                rm -rf /etc/nikki/run/providers 2>/dev/null
                chmod +x /etc/nikki/run/Geo* 2>/dev/null
                log_status "INFO" "Creating symlinks from OpenClash to Nikki..."
                ln -sf /etc/openclash/proxy_provider /etc/nikki/run 2>/dev/null
                ln -sf /etc/openclash/rule_provider /etc/nikki/run 2>/dev/null
                sed -i '64s/Enable/Disable/' /etc/config/alpha 2>/dev/null
                sed -i '170s#.*#<!-- & -->#' /usr/lib/lua/luci/view/themes/alpha/header.htm 2>/dev/null
                ;;
            luci-app-passwall)
                sed -i '88s/Enable/Disable/' /etc/config/alpha 2>/dev/null
                sed -i '171s#.*#<!-- & -->#' /usr/lib/lua/luci/view/themes/alpha/header.htm 2>/dev/null
                ;;
        esac
    else
        log_status "INFO" "$pkg not detected, cleaning up..."
        case "$pkg" in
            luci-app-openclash)
                rm -f /etc/config/openclash1 2>/dev/null
                rm -rf /etc/openclash /usr/share/openclash /usr/lib/lua/luci/view/openclash 2>/dev/null
                sed -i '104s/Enable/Disable/' /etc/config/alpha 2>/dev/null
                sed -i '167s#.*#<!-- & -->#' /usr/lib/lua/luci/view/themes/alpha/header.htm 2>/dev/null
                sed -i '187s#.*#<!-- & -->#' /usr/lib/lua/luci/view/themes/alpha/header.htm 2>/dev/null
                sed -i '188s#.*#<!-- & -->#' /usr/lib/lua/luci/view/themes/alpha/header.htm 2>/dev/null
                ;;
            luci-app-nikki)
                rm -rf /etc/config/nikki /etc/nikki 2>/dev/null
                sed -i '120s/Enable/Disable/' /etc/config/alpha 2>/dev/null
                sed -i '168s#.*#<!-- & -->#' /usr/lib/lua/luci/view/themes/alpha/header.htm 2>/dev/null
                ;;
            luci-app-passwall)
                rm -f /etc/config/passwall 2>/dev/null
                sed -i '136s/Enable/Disable/' /etc/config/alpha 2>/dev/null
                sed -i '169s#.*#<!-- & -->#' /usr/lib/lua/luci/view/themes/alpha/header.htm 2>/dev/null
                ;;
        esac
    fi
done
log_status "SUCCESS" "Tunnel applications configured"

# konfigurasi uhttpd dan PHP8
log_status "INFO" "Configuring uhttpd and PHP8..."

# uhttpd configuration
uci set uhttpd.main.ubus_prefix='/ubus' 2>/dev/null
uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi' 2>/dev/null
uci set uhttpd.main.index_page='cgi-bin/luci' 2>/dev/null
uci add_list uhttpd.main.index_page='index.html' 2>/dev/null
uci add_list uhttpd.main.index_page='index.php' 2>/dev/null
uci commit uhttpd 2>/dev/null

# PHP configuration
if [ -f "/etc/php.ini" ]; then
    cp /etc/php.ini /etc/php.ini.bak 2>/dev/null
    sed -i 's|^memory_limit = .*|memory_limit = 128M|g' /etc/php.ini 2>/dev/null
    sed -i 's|^max_execution_time = .*|max_execution_time = 60|g' /etc/php.ini 2>/dev/null
    sed -i 's|^display_errors = .*|display_errors = Off|g' /etc/php.ini 2>/dev/null
    sed -i 's|^;*date\.timezone =.*|date.timezone = Asia/Jakarta|g' /etc/php.ini 2>/dev/null
    log_status "SUCCESS" "PHP settings configured"
else
    log_status "WARNING" "/etc/php.ini not found, skipping PHP configuration"
fi

if [ -d /usr/lib/php8 ]; then
    ln -sf /usr/lib/php8 2>/dev/null
fi

/etc/init.d/uhttpd restart >/dev/null 2>&1
log_status "SUCCESS" "uhttpd and PHP8 configuration completed"

log_status "SUCCESS" "All setup completed successfully"
rm -rf /etc/uci-defaults/$(basename "$0") 2>/dev/null

log_status "INFO" "========================================="
log_status "INFO" "Crash-Wrt Setup Script Finished"
log_status "INFO" "Check log file: $LOG_FILE"
log_status "INFO" "========================================="

sync
sleep 7
reboot

exit 0
