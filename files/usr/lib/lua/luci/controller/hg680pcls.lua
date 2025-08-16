module("luci.controller.hg680pcls", package.seeall)

function index()
	-- Masuk menu: Services -> HG680P LED Monitor
	entry({"admin","services","hg680pcls"}, cbi("hg680pcls"), _("HG680P LED Monitor"), 60).dependent = true

	-- Endpoint aksi start/stop/restart (dipakai tombol di view)
	entry({"admin","services","hg680pcls","action"}, call("do_action")).leaf = true
end

function do_action()
	local http = require "luci.http"
	local sys  = require "luci.sys"

	local act = http.formvalue("do")
	if act == "start" then
		sys.call("/etc/init.d/hg680pcls start >/dev/null 2>&1")
	elseif act == "stop" then
		sys.call("/etc/init.d/hg680pcls stop >/dev/null 2>&1")
	elseif act == "restart" then
		sys.call("/etc/init.d/hg680pcls restart >/dev/null 2>&1")
	end
	http.redirect(luci.dispatcher.build_url("admin/services/hg680pcls"))
end
