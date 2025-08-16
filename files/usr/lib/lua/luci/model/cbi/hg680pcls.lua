local sys = require "luci.sys"
local fs  = require "nixio.fs"

m = Map("hg680pcls", translate("HG680P LED Monitor"),
	translate("Mengatur service yang mengubah LED HG680P berdasarkan hasil ping."))

s = m:section(TypedSection, "hg680pcls", translate("Pengaturan"))
s.anonymous = true

-- Aktifkan service
o = s:option(Flag, "enabled", translate("Aktifkan service"))
o.rmempty = false

-- Host/IP target
o = s:option(Value, "target_host", translate("Target Host/IP"))
o.datatype = "host"
o.placeholder = "bing.com"
o.default = "bing.com"
o.rmempty = false

-- Interval (detik)
o = s:option(Value, "interval", translate("Interval (detik)"))
o.datatype = "uinteger"
o.placeholder = "5"
o.default = "5"
o.rmempty = false

-- Status
local st = s:option(DummyValue, "_status", translate("Status Service"))
st.rawhtml = true
st.cfgvalue = function()
	local pid = fs.readfile("/tmp/hg680pcls.pid") or ""
	local running = (pid ~= "" and sys.call("kill -0 $(cat /tmp/hg680pcls.pid) 2>/dev/null") == 0)
	local state = (fs.readfile("/tmp/hg680pcls.state") or ""):gsub("%s+$","")
	local badge = running and '<span class="badge badge-success">Running</span>'
	                           or '<span class="badge badge-danger">Stopped</span>'
	local state_html = state ~= "" and ('<span class="badge badge-info">State: '..state..'</span>') or ""
	return string.format('<div class="cbi-value"><div class="cbi-value-field">%s&nbsp;%s</div></div>', badge, state_html)
end

-- Tombol kontrol
local ctl = s:option(DummyValue, "_controls", translate("Kontrol Service"))
ctl.template = "hg680pcls/controls"

return m
