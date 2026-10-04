
local ProxyType = "powerproxy.paratroopers"
local ParadropWaypoints = { Drop1, Drop2, Drop3, Drop4, Drop5, Drop6, Drop7 }
local SpainReinforceUnits = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
local SpainReinforceUnitsSmall = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
local USSRReinforceUnits = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
local WaterTanks = { "1tnk", "1tnk", "jeep", "jeep" }
local USSRBldgs = { USSRpwr1, USSRpwr2, USSRoreref, USSRcy1, USSRsubpen1 }

local StartTimer = false
local TimerColor = Player.GetPlayer("USSR").Color
local EndTimerColor = Player.GetPlayer("Spain").Color
local TimerTicks = DateTime.Minutes(1)
local Ticked = TimerTicks
local doOnce1 = false

---@type player
local Allies1
---@type player
local Allies2
---@type player
local Allies

---@type player
local USSR

---@type player
local Spain

local StartTimerFunction = function()
	StartTimer = true
end


local TransitArriveTimerEnd = function(hpad)
	local units = Reinforcements.ReinforceWithTransport(USSR, "tran",
			USSRReinforceUnits, { HeliEnter.Location, USSRHpad.Location + CVec.New(1, 2) }, { HeliEnter.Location })[2]
	USSRHFlare.Destroy()
	Allies1.MarkFailedObjective(NoLetHeliObj)
	SendUnits(Spain, SpainInvEnter, SpainInvRally, SpainReinforceUnitsSmall, 1)

	Utils.Do(units, function(unit)
		if unit.Owner == USSR then
			Trigger.OnIdle(unit, function(a)
				if a.IsInWorld then
					a.AttackMove(USSRattk.Location)
				end
			end)
		elseif unit.Owner == Spain then
			Trigger.OnIdle(unit, function(a)
				if a.IsInWorld then
					a.AttackMove(SpainInvRally.Location)
				end
			end)
		end
	end)
end

Tick = function()
	if StartTimer then
		if Ticked > 0 then
			if (Ticked % DateTime.Seconds(1)) == 0 then
				Timer = UserInterface.Translate("enemy-trans-arrive", { ["time"] = Utils.FormatTime(Ticked) })
				UserInterface.SetMissionText(Timer, TimerColor)
			end
			Ticked = Ticked - 1
		elseif Ticked == 0 then
			TransitArriveTimerEnd()
			Timer = UserInterface.Translate("enemy-trans-arrived")
			UserInterface.SetMissionText(Timer, EndTimerColor)
			Ticked = Ticked - 1
		end
	end

	if USSRHpad.IsDead and not doOnce1 then
		doOnce1 = true
		Allies1.MarkCompletedObjective(NoLetHeliObj)
		Media.DisplayMessage(UserInterface.Translate("additional-reinforce"))
		ParadropUnits(Allies1)
		ParadropUnits(Allies2)
	end

	local allDead = USSRBldgs[1].IsDead and USSRBldgs[1].IsDead and USSRBldgs[1].IsDead and USSRBldgs[1].IsDead and USSRBldgs[1].IsDead
	if allDead then
		Allies1.MarkCompletedObjective(DestroyBaddiesObj)
		Allies1.MarkCompletedObjective(NoLetHeliObj)
	end

	if Allies2.HasNoRequiredUnits() then
		if Allies1.HasNoRequiredUnits() then
			if Allies.HasNoRequiredUnits() then
				USSR.MarkCompletedObjective(BeatAllies)
			end
		end
	end
end

local ParadropUnits = function(playerOwner)
	local PowerProxy = Actor.Create(ProxyType, false, { Owner = playerOwner })
	local lz = Utils.Random(ParadropWaypoints)
	PowerProxy.TargetParatroopers(lz.CenterPosition, Angle.East)
end

local SendUnits = function(playerOwner, enter, rally, types, timeInterval)
	local units = Reinforcements.Reinforce(playerOwner, types, { enter.Location }, timeInterval)
	for i = 1, table.getn(units) do
		units[i].AttackMove(rally.Location)
	end
end

local SendWaterUnits = function(playerOwner, types, enter, rally, exit)
	exit = exit or enter
	local units = Reinforcements.ReinforceWithTransport(playerOwner, "lst",
			types, { enter.Location, rally.Location }, { exit.Location })[2]
end

WorldLoaded = function()
	Allies1 = Player.GetPlayer("Allies1")
	Allies2 = Player.GetPlayer("Allies2")
	Allies = Player.GetPlayer("Allies")

	USSR = Player.GetPlayer("USSR")
	Spain = Player.GetPlayer("Spain")


	Trigger.AfterDelay(DateTime.Seconds(35), function()
		SendUnits(Spain, SpainInvEnter, SpainInvRally, SpainReinforceUnits, 0)
		local cam = Actor.Create("Camera", true, { Owner = Allies1, Location = bgInvCam1.Location })
		Trigger.AfterDelay(DateTime.Seconds(19), function()
			local cam = Actor.Create("Camera", true, { Owner = Allies1, Location = bgInvCam2.Location })
		end)
	end)

	InitObjectives(Allies1)
	DestroyBaddiesObj = AddPrimaryObjective(Allies1, "destroy-baddies")
	NoLetHeliObj = AddSecondaryObjective(Allies1, "no-let-heli")

	BeatAllies = AddPrimaryObjective(USSR, "")

	Trigger.AfterDelay(DateTime.Seconds(5), function()
		Media.DisplayMessage(UserInterface.Translate("s-1"))
		ParadropUnits(Allies1)
		ParadropUnits(Allies1)
		ParadropUnits(Allies2)
		ParadropUnits(Allies2)
		Trigger.AfterDelay(DateTime.Seconds(25), function()
			Media.DisplayMessage(UserInterface.Translate("s-2"))
			SendWaterUnits(Allies1, WaterTanks, WaterEnter, Land1)
			Trigger.AfterDelay(DateTime.Seconds(3), function()
				SendWaterUnits(Allies1, WaterTanks, WaterEnter, Land2)
				Trigger.AfterDelay(DateTime.Seconds(3), function()
					SendWaterUnits(Allies2, WaterTanks, WaterEnter, Land3)
					Trigger.AfterDelay(DateTime.Seconds(3), function()
						SendWaterUnits(Allies2, WaterTanks, WaterEnter, Land4)
						Media.DisplayMessage(UserInterface.Translate("s-3"))
					end)
				end)
			end)
		end)
	end)

	StartTimerFunction()
end