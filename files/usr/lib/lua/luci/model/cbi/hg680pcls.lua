m = Map("hg680pcls", "HG680P LED Control",
    [[<div style='text-align:center;'>
    <b>Created Crashoverride | Crash-Wrt</b><br>
    GitHub: <a href='https://github.com/syamsulsariphidayat7' target='_blank'>
    Syamsul Sarip Hidayat</a>
    </div>]]
)

s = m:section(TypedSection, "hg680pcls", "Settings")
s.anonymous = true
s.addremove = false

-- Power LED mode
pmode = s:option(ListValue, "power_mode", "Power LED Mode")
pmode:value("off", "Off")
pmode:value("on", "On")
pmode:value("heart", "Heart")
pmode:value("disko", "Disko")

-- LAN LED mode
lmode = s:option(ListValue, "lan_mode", "LAN LED Mode")
lmode:value("off", "Off")
lmode:value("on", "On")
lmode:value("heart", "Heart")
lmode:value("disko", "Disko")

-- Ping targets
ping_targets = s:option(Value, "ping_targets", "Ping Targets (space separated)")
ping_targets.default = "8.8.8.8 1.1.1.1 104.17.156.243"

-- Interval
interval = s:option(Value, "interval", "Check Interval (sec)")
interval.datatype = "uinteger"
interval.default = 5

-- Info box
local btn_note = m:section(SimpleSection)
btn_note.template = "cbi/nullsection"
btn_note.render = function()
    luci.http.write("<div class='alert alert-info text-center'>")
    luci.http.write("<i class='fa fa-info-circle' style='color: #F0AD4E;'></i> ")
    luci.http.write("<span style='color:orange;'>")
    luci.http.write("Gunakan dulu <b>Save &amp; Apply</b> di bawah untuk menyimpan konfigurasi, gunakan tombol <b>Apply & Restart Service</b> di atas untuk jalankan service.")
    luci.http.write("</span>")
    luci.http.write("</div>")
end

-- Tombol Apply & Restart Service
btn = s:option(Button, "_apply", "Apply & Restart Service")
btn.inputstyle = "apply"
function btn.write(self, section)
    luci.sys.call("/etc/init.d/hg680pcls restart >/dev/null 2>&1 &")
end

m.submit = false
m.reset  = false

return m
