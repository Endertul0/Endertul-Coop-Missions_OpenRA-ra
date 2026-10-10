
local PTroopersProxyType = "powerproxy.paratroopers"
local ParadropWaypoints = { Drop1, Drop2, Drop3, Drop4, Drop5, Drop6, Drop7 }
local SpainReinforceUnits = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
local SpainReinforceUnitsSmall = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
local USSRReinforceUnits = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
local WaterTanks = { "1tnk", "1tnk", "jeep", "jeep" }
local USSRBldgs = { USSRpwr1, USSRpwr2, USSRoreref, USSRcy1, USSRsubpen1 }

local TimerStarted = false
local TimerColor = Player.GetPlayer("USSR").Color
local TimerEndColor = Player.GetPlayer("Spain").Color
local TimerTotalTicks = DateTime.Minutes(1)
local TimerTicks = TimerTotalTicks
local USSRHpadSlain = false

---@param playerOwner player
local ParadropUnits = function(playerOwner)
	local PowerProxy = Actor.Create(PTroopersProxyType, false, { Owner = playerOwner })
	local lz = Utils.Random(ParadropWaypoints)
	PowerProxy.TargetParatroopers(lz.CenterPosition, Angle.East)
end

---@param playerOwner player
---@param enter actor
---@param rally actor
---@param types string[]
---@param timeInterval integer
---@return table
local SendUnits = function(playerOwner, enter, rally, types, timeInterval)
	local units = Reinforcements.Reinforce(playerOwner, types, { enter.Location }, timeInterval)
    for i = 1, #units do
        units[i].AttackMove(rally.Location)
    end

    return units
end

---@param playerOwner player
---@param types string[]
---@param enter actor
---@param rally actor
---@param exit? actor
---@return table
local SendWaterUnits = function(playerOwner, types, enter, rally, exit)
	exit = exit or enter
	local units = Reinforcements.ReinforceWithTransport(playerOwner, "lst",
			types, { enter.Location, rally.Location }, { exit.Location })[2]

	return units
end

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
	TimerStarted = true
end

local TransitArriveTimerEnd = function()
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
	if TimerStarted then
		if TimerTicks > 0 then
			if (TimerTicks % DateTime.Seconds(1)) == 0 then
				Timer = UserInterface.Translate("enemy-trans-arrive", { ["time"] = Utils.FormatTime(TimerTicks) })
				UserInterface.SetMissionText(Timer, TimerColor)
			end
			TimerTicks = TimerTicks - 1
		elseif TimerTicks == 0 then
			TransitArriveTimerEnd()
			Timer = UserInterface.Translate("enemy-trans-arrived")
			UserInterface.SetMissionText(Timer, TimerEndColor)
			TimerTicks = TimerTicks - 1
		end
	end

	if USSRHpad.IsDead and not USSRHpadSlain then
		USSRHpadSlain = true
		Allies1.MarkCompletedObjective(NoLetHeliObj)
		Media.DisplayMessage(UserInterface.Translate("additional-reinforce"))
		ParadropUnits(Allies1)
		ParadropUnits(Allies2)
	end

	local allDead = true
	for _, bldg in ipairs(USSRBldgs) do
		if not bldg.IsDead then
			allDead = false
			break
		end
	end
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

WorldLoaded = function()
	Allies1 = Player.GetPlayer("Allies1")
	Allies2 = Player.GetPlayer("Allies2")
	Allies = Player.GetPlayer("Allies")

	USSR = Player.GetPlayer("USSR")
	Spain = Player.GetPlayer("Spain")


	Trigger.AfterDelay(DateTime.Seconds(35), function()
		SendUnits(Spain, SpainInvEnter, SpainInvRally, SpainReinforceUnits, 0)
		Actor.Create("Camera", true, { Owner = Allies1, Location = bgInvCam1.Location })
		Trigger.AfterDelay(DateTime.Seconds(19), function()
			Actor.Create("Camera", true, { Owner = Allies1, Location = bgInvCam2.Location })
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