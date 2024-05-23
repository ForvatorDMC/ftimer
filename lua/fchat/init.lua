fchat = fchat or {}

fchat.ranks = {}
fchat.restrictions = {}

AddCSLuaFile("sh_utilities.lua")
AddCSLuaFile("sh_config.lua")
AddCSLuaFile("cl_expression.lua")
AddCSLuaFile("cl_theme.lua")
AddCSLuaFile("cl_panel.lua")

AddCSLuaFile("gui/frame.lua")
AddCSLuaFile("gui/config.lua")
AddCSLuaFile("gui/slider.lua")
AddCSLuaFile("gui/expression_list.lua")
AddCSLuaFile("gui/form.lua")
AddCSLuaFile("gui/rank_list.lua")
AddCSLuaFile("gui/editor.lua")
AddCSLuaFile("gui/mysql.lua")
AddCSLuaFile("gui/restrictions.lua")
AddCSLuaFile("gui/chatroom.lua")

include("sh_utilities.lua")
include("sh_config.lua")
include("sv_sql.lua")
include("cl_theme.lua") -- Nothing is actually used serverside.

resource.AddFile("materials/fchat/plus.png")
resource.AddFile("materials/fchat/cross.png")
resource.AddFile("materials/fchat/check.png")
resource.AddFile("materials/fchat/users.png")
resource.AddFile("materials/fchat/emotes.png")
resource.AddFile("materials/fchat/settings.png")

resource.AddFile("materials/fchat/emoticons/overrustle.png")
resource.AddFile("materials/fchat/emoticons/garry.png")
resource.AddFile("materials/fchat/emoticons/gaben.png")

resource.AddFile("resource/fonts/opensans_bold.ttf")
resource.AddFile("resource/fonts/opensans_bolditalic.ttf")
resource.AddFile("resource/fonts/opensans_extrabold.ttf")
resource.AddFile("resource/fonts/opensans_extrabolditalic.ttf")
resource.AddFile("resource/fonts/opensans_italic.ttf")
resource.AddFile("resource/fonts/opensans_light.ttf")
resource.AddFile("resource/fonts/opensans_lightitalic.ttf")
resource.AddFile("resource/fonts/opensans_regular.ttf")
resource.AddFile("resource/fonts/opensans_semibold.ttf")
resource.AddFile("resource/fonts/opensans_semibolditalic.ttf")

-- configuration ot add usergroups to a whitelist of who can edit stuff

----------------------------------------------------------------------	
-- Purpose:
--		
----------------------------------------------------------------------
 
hook.Add("Initialize", "fchat.Initialize", function()
	local version = file.Read("fchat_version.txt", "DATA")
	
	if (version) then
		FCHAT_VERSION_PREVIOUS = tonumber(version)
	end
	
	file.Write("fchat_version.txt", tostring(FCHAT_VERSION), "DATA")
	
	fchat.sql.Initialize()
end)

----------------------------------------------------------------------	
-- Purpose:
--		Called when the database has connected.
----------------------------------------------------------------------

hook.Add("fchat.DatabaseConnected", "1", function(remote, firstTime)
	if (firstTime) then
		fchat.sql.Query("CREATE TABLE IF NOT EXISTS fchat_players(id INTEGER PRIMARY KEY " .. (remote and "AUTO_INCREMENT" or "") .. ", steamID TEXT, title TEXT)")
		fchat.sql.Query("CREATE TABLE IF NOT EXISTS fchat_ranks(id INTEGER PRIMARY KEY " .. (remote and "AUTO_INCREMENT" or "") .. ", usergroup TEXT, icon TEXT, tag TEXT)")
		fchat.sql.Query("CREATE TABLE IF NOT EXISTS fchat_restrictions(id INTEGER PRIMARY KEY " .. (remote and "AUTO_INCREMENT" or "") .. ", expression TEXT, usergroups TEXT)")
		
		fchat.sql.Query("SELECT * FROM fchat_ranks", function(data, query)
			if (data) then
				for i = 1, #data do
					local info = data[i]
					
					fchat.ranks[info.usergroup] = {tag = info.tag, icon = info.icon}
				end
			end
		end)
		
		fchat.sql.Query("SELECT * FROM fchat_restrictions", function(data, query)
			if (data) then
				for i = 1, #data do
					local info = data[i]
					
					fchat.restrictions[info.expression] = util.JSONToTable(info.usergroups)
				end
			end
		end)
	end
end)

----------------------------------------------------------------------	
-- Purpose:
--		Called when a player connects to the server.
----------------------------------------------------------------------

util.AddNetworkString("fchat.plcnt")

gameevent.Listen("player_connect")

hook.Add("player_connect", "fchat.PlayerConnect", function(data)
	net.Start("fchat.plcnt")
		net.WriteString(data.name)
		net.WriteString(data.networkid)
	net.Broadcast()
end)

----------------------------------------------------------------------	
-- Purpose:
--		Called when a player wants to load their data.
----------------------------------------------------------------------

util.AddNetworkString("fchat.plload")

net.Receive("fchat.plload", function(bits, player)
	local loaded = player.fchatLoaded
	
	player.nextMessageAtlas = 0
	
	if (!loaded) then
		local steamID = sql.SQLStr(player:SteamID())
		
		fchat.sql.Query("SELECT * FROM fchat_players WHERE steamID=" .. steamID, function(data, query)
			if (IsValid(player)) then
				if (data and #data > 0) then
					data = data[1]
		
					if (data.title and data.title != "" and data.title != "NULL") then
						player:SetNetworkedString("ac_title", data.title)
					end
				else
					fchat.sql.Query("INSERT INTO fchat_players(steamID) VALUES(" .. steamID .. ")")
				end
			end
		end)
		
		timer.Simple(0.2, function()
			if (IsValid(player)) then
				fchat.config.SyncVariables(player)
			end
		end)
		
		for unique, data in pairs(fchat.ranks) do
			local tag = data.tag != NULL and data.tag or ""
			
			net.Start("fchat.crtrnkgt")
				net.WriteString(unique)
				net.WriteString(tag)
				net.WriteString(data.icon)
			net.Send(player)
		end
		
		for expression, usergroups in pairs(fchat.restrictions) do
			local len = table.Count(usergroups)
			
			net.Start("fchat.rstcs")
				net.WriteString(expression)
				net.WriteUInt(len, 8)
				
				for k, v in pairs(usergroups) do
					net.WriteString(k)
				end
				
				net.WriteBit(false)
			net.Send(player)
		end
		
		player.fchatLoaded = true
	end
end)

----------------------------------------------------------------------	
-- Purpose:
--		Setting a players title.
----------------------------------------------------------------------

util.AddNetworkString("fchat.stplttl")

net.Receive("fchat.stplttl", function(bits, player)
	local isAdmin = player:IsSuperAdmin()
	
	if (isAdmin) then
		local target = net.ReadString()
		
		target = util.FindPlayerFchat(target, player)
		
		if (IsValid(target)) then
			local title = net.ReadString()
			local steamID = sql.SQLStr(target:SteamID())
			
			target:SetNetworkedString("ac_title", title)
			
			fchat.sql.Query("UPDATE fchat_players SET title=" .. sql.SQLStr(title) .. " WHERE steamID=" .. steamID)
		end
	end
end)

----------------------------------------------------------------------	
-- Purpose:
--		Creating a new usergroup.
----------------------------------------------------------------------

util.AddNetworkString("fchat.crtrnk")
util.AddNetworkString("fchat.crtrnkex")
util.AddNetworkString("fchat.crtrnkgt")

net.Receive("fchat.crtrnk", function(bits, player)
	local isAdmin = player:IsSuperAdmin()
	
	if (isAdmin) then
		local userGroup = net.ReadString()
		
		if (fchat.ranks[userGroup] != nil) then
			fchat.Notify(":exclamation: Could not create the usergroup: The usergroup already exist!", player)
		else
			fchat.ranks[userGroup] = {tag = "", icon = "icon16/user.png"}
			
			fchat.sql.Query("INSERT INTO fchat_ranks(id, usergroup, icon, tag) VALUES(NULL, " .. sql.SQLStr(userGroup) .. ", " .. sql.SQLStr("icon16/user.png") .. ", " .. sql.SQLStr("") .. ")")
			
			net.Start("fchat.crtrnkgt")
				net.WriteString(userGroup)
				net.WriteString("")
				net.WriteString("icon16/user.png")
			net.Broadcast()
			
			fchat.Notify(":information: Successfully created the usergroup '" .. userGroup .. "'!", player)
		end
	end
end)

----------------------------------------------------------------------	
-- Purpose:
--		Removing a usergroup.
----------------------------------------------------------------------

util.AddNetworkString("fchat.rmvrnk")

net.Receive("fchat.rmvrnk", function(bits, player)
	local isAdmin = player:IsSuperAdmin()
	
	if (isAdmin) then
		local userGroup = net.ReadString()
		
		if (fchat.ranks[userGroup]) then
			fchat.ranks[userGroup] = nil
			
			fchat.sql.Query("DELETE FROM fchat_ranks WHERE usergroup = " .. sql.SQLStr(userGroup))
			
			net.Start("fchat.crtrnkgt")
				net.WriteString(userGroup)
				net.WriteString("")
				net.WriteString("")
				net.WriteUInt(1, 8)
			net.Broadcast()
			
			fchat.Notify(":information: Successfully removed the usergroup '" .. userGroup .. "'!", player)
		else
			fchat.Notify(":exclamation: Could not remove the usergroup: The usergroup does not exist!", player)
		end
	end
end)

----------------------------------------------------------------------	
-- Purpose:
--		Changing the icon & title of a usergroup.
----------------------------------------------------------------------

util.AddNetworkString("fchat.chnric")

net.Receive("fchat.chnric", function(bits, player)
	local isAdmin = player:IsSuperAdmin()
	
	if (isAdmin) then
		local userGroup = net.ReadString()
		
		if (fchat.ranks[userGroup]) then
			local tag = net.ReadString()
			local icon = net.ReadString()
			
			fchat.ranks[userGroup] = {tag = tag, icon = icon}
			
			fchat.sql.Query("UPDATE fchat_ranks SET icon = " .. sql.SQLStr(icon) .. ", tag = " .. sql.SQLStr(tag) .. " WHERE usergroup = " .. sql.SQLStr(userGroup))
			
			net.Start("fchat.crtrnkgt")
				net.WriteString(userGroup)
				net.WriteString(tag)
				net.WriteString(icon)
				net.WriteUInt(2, 8)
			net.Broadcast()
			
			fchat.Notify(":information: Successfully changed the icon/tag of usergroup '" .. userGroup .. "' to '" .. icon .. "  -  " .. tag .. "'!", player)
		else
			fchat.Notify(":exclamation: Could not change the icon/tag: The usergroup does not exist!", player)
		end
	end
end)

----------------------------------------------------------------------	
-- Purpose:
--		Adding & removing expression restrictions.
----------------------------------------------------------------------

util.AddNetworkString("fchat.rstcs")

net.Receive("fchat.rstcs", function(bits, player)
	local isAdmin = player:IsSuperAdmin()
	
	if (isAdmin) then
		local remove = util.tobool(net.ReadBit())
		local expression = net.ReadString()
		local usergroup = net.ReadString()
		
		fchat.restrictions[expression] = fchat.restrictions[expression] or {}
		
		if (remove) then
			fchat.restrictions[expression][usergroup] = nil
		else
			fchat.restrictions[expression][usergroup] = true
		end
		
		net.Start("fchat.rstcs")
			net.WriteString(expression)
			net.WriteUInt(1, 8)
			net.WriteString(usergroup)
			net.WriteBit(remove)
		net.Broadcast()
		
		-- Lazy way of storing data.
		local info = util.TableToJSON(fchat.restrictions[expression])
		
		if (fchat.sql.IsRemote()) then
			fchat.sql.Query("SELECT id FROM fchat_restrictions WHERE expression = " .. sql.SQLStr(expression), function(data, query)
				if (#data > 0) then
					fchat.sql.Query("UPDATE fchat_restrictions SET usergroups = " .. sql.SQLStr(info) .. " WHERE expression = " .. sql.SQLStr(expression))
				else
					fchat.sql.Query("INSERT INTO fchat_restrictions(id, expression, usergroups) VALUES(NULL, " .. sql.SQLStr(expression) .. ", " .. sql.SQLStr(info) .. ")")
				end
			end)
		else
			fchat.sql.Query("INSERT OR REPLACE INTO fchat_restrictions(id, expression, usergroups) VALUES((SELECT id FROM fchat_restrictions WHERE expression = " .. sql.SQLStr(expression) .. "), " .. sql.SQLStr(expression) .. ", " .. sql.SQLStr(info) .. ")")
		end
	end
end)

---------------------------------------------------------
-- Private chatting.
---------------------------------------------------------

local privateMessages = {}

---------------------------------------------------------
-- Creating a private chat.
---------------------------------------------------------

util.AddNetworkString("fchat.stpm")
util.AddNetworkString("fchat.nwpm")

net.Receive("fchat.stpm", function(bits, player)
	local key, count = nil, table.Count(privateMessages)
	
	for i = 1, count do
		if (privateMessages[i] == nil) then
			key = i
			
			break
		end
	end
	
	if (!key) then key = count +1 end
	
	privateMessages[key] = {players = {player}, creator = player}

	net.Start("fchat.nwpm")
		net.WriteUInt(key, 8)
	net.Send(player)
	
	local data = privateMessages[key]
	
	net.Start("fchat.gtplpm")
		net.WriteUInt(key, 8)
		net.WriteUInt(#data.players, 8)
		
		for i = 1, #data.players do
			net.WriteEntity(data.players[i])
		end
		
		net.WriteEntity(data.creator)
	net.Send(player)
end)

---------------------------------------------------------
-- Sending a text message in a private chat.
---------------------------------------------------------

util.AddNetworkString("fchat.rxpm")
util.AddNetworkString("fchat.txpm")

net.Receive("fchat.txpm", function(bits, player)
	if (player.nextMessageAtlas > CurTime()) then return end
	
	player.nextMessageAtlas = CurTime() +0.25
	
	-- Don't allow dead players in TTT to private chat!
	if (TellTraitorsAboutTraitors) then
		if (player:IsSpec() and GAMEMODE.round_state == ROUND_ACTIVE and DetectiveMode()) then
			player:ChatPrint("You cannot talk in private chats in this state.")

			return
		end
	end
	
	local key = net.ReadUInt(8)
	local text = net.ReadString()
	local receivers = privateMessages[key]
	
	if (receivers) then
		receivers = receivers.players
		
		text = string.sub(text, 0, 127)
		
		net.Start("fchat.rxpm")
			net.WriteUInt(key, 8)
			net.WriteString(text)
			net.WriteEntity(player)
		net.Send(receivers)
		
		ServerLog("[fchat] (PM) " .. player:Nick() .. ": " .. text .. "\n")
	end
end)

---------------------------------------------------------
-- Leaving a private chat.
---------------------------------------------------------

util.AddNetworkString("fchat.lvpm")

net.Receive("fchat.lvpm", function(bits, player)
	local key = net.ReadUInt(8)
	local data = privateMessages[key]
	
	if (data) then
		for i = 1, #data.players do
			local value = data.players[i]
			
			if (value == player) then
				table.remove(data.players, i)
				
				break
			end
		end
		
		net.Start("fchat.nkickpm")
			net.WriteUInt(key, 8)
			net.WriteEntity(player)
			net.WriteBit(true)
		net.Send(data.players)
		
		if (#data.players <= 0) then
			privateMessages[key] = nil
		end
	end
end)

---------------------------------------------------------
-- Joining a private chat.
---------------------------------------------------------

util.AddNetworkString("fchat.jnpm")
util.AddNetworkString("fchat.gtplpm")

net.Receive("fchat.jnpm", function(bits, player)
	local key = net.ReadUInt(8)
	local data = privateMessages[key]

	if (data) then
		local exists = false
		
		for i = 1, #data.players do
			local info = data.players[i]
			
			if (info == player) then
				exists = true
				
				break
			end
		end
		
		if (!exists) then
			table.insert(data.players, player)
			
			-- Send information about the chat room to the player.
			net.Start("fchat.gtplpm")
				net.WriteUInt(key, 8)
				net.WriteUInt(#data.players, 8)
				
				for i = 1, #data.players do
					net.WriteEntity(data.players[i])
				end
				
				net.WriteEntity(data.creator)
			net.Send(player)
			
			-- Network that this player has joined the chat room.
			net.Start("fchat.gtplpm")
				net.WriteUInt(key, 8)
				net.WriteUInt(1, 8)
				net.WriteEntity(player)
			net.Send(data.players)
		end
	end
end)

---------------------------------------------------------
-- Kicking a player from a private chat.
---------------------------------------------------------

util.AddNetworkString("fchat.kickpm")
util.AddNetworkString("fchat.nkickpm")

net.Receive("fchat.kickpm", function(bits, player)
	local key = net.ReadUInt(8)
	local data = privateMessages[key]
	
	if (data) then
		if (data.creator == player) then
			local target = net.ReadEntity()
		
			for i = 1, #data.players do
				local info = data.players[i]
				
				if (info == target) then
					net.Start("fchat.nkickpm")
						net.WriteUInt(key, 8)
						net.WriteEntity(target)
						net.WriteBit(false)
					net.Send(data.players)
					
					table.remove(data.players, i)
					
					break
				end
			end
		end
	end
end)

---------------------------------------------------------
-- Inviting a player to a private chat.
---------------------------------------------------------

util.AddNetworkString("fchat.invpm")
util.AddNetworkString("fchat.sinvpm")

net.Receive("fchat.invpm", function(bits, player)
	local key = net.ReadUInt(8)
	local target = net.ReadString()
	
	target = util.FindPlayerFchat(target, player)
	
	if (IsValid(target)) then
		net.Start("fchat.sinvpm")
			net.WriteUInt(key, 8)
			net.WriteEntity(player)
		net.Send(target)
	end
end)

---------------------------------------------------------
-- Clears your configuration.
---------------------------------------------------------

util.AddNetworkString("fchat.clrcfg")
util.AddNetworkString("fchat.rqclrcfg")

net.Receive("fchat.rqclrcfg", function(bits, player)
	local target = net.ReadString()
	
	if (target != "") then
		target = util.FindPlayerFchat(target, player)
		
		if (IsValid(target)) then
			if (target != player and !player:IsAdmin()) then return end
			
			net.Start("fchat.clrcfg")
			net.Send(target)
			
			if (target == player) then
				fchat.Notify("Successfully reset your fchat configuration! Close and open your chatbox to apply.", target)
			else
				fchat.Notify(player:Nick() .. " has reset your fchat configuration! Close and open your chatbox to apply.", target)
				fchat.Notify("You have reset " .. target:Nick() .. "'s fchat configuration! Close and open your chatbox to apply.", player)
			end
		end
	else
		if (player:IsAdmin()) then
			net.Start("fchat.clrcfg")
			net.Broadcast()
			
			fchat.Notify(player:Nick() .. " has reset everyone's fchat configuration! Close and open your chatbox to apply.")
		end
	end
end)

---------------------------------------------------------
-- F Chat messages.
---------------------------------------------------------

util.AddNetworkString("fchat.msg")

function fchat.Notify(text, player)
	net.Start("fchat.msg")
		net.WriteString(text)
	if (IsValid(player)) then net.Send(player) else net.Broadcast() end
end

---------------------------------------------------------
-- Net message for larger text!
---------------------------------------------------------

util.AddNetworkString("fchat.chat")
util.AddNetworkString("fchat.chatText")

local isstring = isstring

net.Receive("fchat.chat", function(bits, player)
	if (player.nextMessageAtlas > CurTime()) then return end
	
	player.nextMessageAtlas = CurTime() +0.25
	
	local text = net.ReadString()
	local team = util.tobool(net.ReadBit())
	
	text = string.sub(text, 0, 127)
	
	local newText = hook.Run("PlayerSay", player, text, team, !player:Alive())
	
	-- A workaround for dumb coders that return a boolean in the PlayerSay hook.
	if (isstring(newText)) then
		text = newText
	elseif (not newText) then
		text = ""
	end
	
	if (text != "") then
		if (game.IsDedicated()) then
			ServerLog(player:Nick() .. ": " .. text .. "\n")
		end
		
		local filter = {}
		local players = util.GetPlayers()
		
		for i = 1, #players do
			local target = players[i]
			
			if (IsValid(target)) then
				local canSee = hook.Run("PlayerCanSeePlayersChat", text, team, target, player)
				
				if (canSee or target == player) then
					table.insert(filter, target)
				end
			end
		end
		
		net.Start("fchat.chatText")
			net.WriteString(text)
			net.WriteEntity(player)
			net.WriteBit(team)
		net.Send(filter)
	end
end)

----------------------------------------------------------------------	
-- Purpose:
--		Sets "Player.IsTyping"
----------------------------------------------------------------------

util.AddNetworkString("fchat.istyping")

net.Receive("fchat.istyping", function(bits, player)
	local bool = util.tobool(net.ReadBit())
	
	player:SetNetworkedBool("fchat.istyping", bool)
end)

----------------------------------------------------------------------	
-- Purpose:
--		Returns true/false if the player is/isn't typing.
----------------------------------------------------------------------

function PLAYER_META:IsTyping()
	return self:GetNetworkedBool("fchat.istyping")
end

