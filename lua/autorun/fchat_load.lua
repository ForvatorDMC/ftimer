AddCSLuaFile()

FCHAT_VERSION = 001

if (SERVER) then
	AddCSLuaFile("fchat/cl_init.lua")
	
	include("fchat/init.lua")
else
	include("fchat/cl_init.lua")
end

if (fchat) then
	local version = ""
	
	string.gsub(tostring(FCHAT_VERSION), "(%d)", function(text) version = version .. text .. "." end)
	
	function fchat:GetVersion()
		return version:sub(0, 5)
	end
	
	if (CLIENT) then
		MsgC(color_green, "F Chat")
	else
		MsgC(color_green, "F Chat")
	end
else
	MsgC(color_red, "F Chat failed to load!\n")
end