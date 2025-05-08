
ProxyType = "powerproxy.paratroopers"
ParadropWaypoints = { Drop1, Drop2, Drop3, Drop4, Drop5, Drop6, Drop7 }
SpainReinforceUnits = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
SpainReinforceUnitsSmall = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
USSRReinforceUnits = { "e1", "e2", "e3", "e4", "e1", "e2", "e3", "e4" }
WaterTanks = { "1tnk", "1tnk", "jeep", "jeep" }
USSRBldgs = { USSRpwr1, USSRpwr2, USSRoreref, USSRcy1, USSRsubpen1 }

StartTimer = false
TimerColor = Player.GetPlayer("USSR").Color
EndTimerColor = Player.GetPlayer("Spain").Color
TimerTicks = DateTime.Minutes(1)
Ticked = TimerTicks
doOnce1 = false

StartTimerFunction = function()
	StartTimer = true
end


TransitArriveTimerEnd = function(hpad)
	local units = Reinforcements.ReinforceWithTransport(USSR, "tran",
			USSRReinforceUnits, { HeliEnter.Location, USSRHpad.Location + CVec.New(1, 2) }, { HeliEnter.Location })[2]
	USSRHFlare.Destroy()
	GoodGuy.MarkFailedObjective(NoLetHeliObj)
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
		GoodGuy.MarkCompletedObjective(NoLetHeliObj)
		Media.DisplayMessage(UserInterface.Translate("additional-reinforce"))
		ParadropUnits(GoodGuy)
		ParadropUnits(Greece)
	end

	local allDead = USSRBldgs[1].IsDead and USSRBldgs[1].IsDead and USSRBldgs[1].IsDead and USSRBldgs[1].IsDead and USSRBldgs[1].IsDead
	if allDead then
		GoodGuy.MarkCompletedObjective(DestroyBaddiesObj)
		GoodGuy.MarkCompletedObjective(NoLetHeliObj)
	end

	if Greece.HasNoRequiredUnits() then
		if GoodGuy.HasNoRequiredUnits() then
			if Allies.HasNoRequiredUnits() then
				USSR.MarkCompletedObjective(BeatAllies)
			end
		end
	end
end

ParadropUnits = function(playerOwner)
	local PowerProxy = Actor.Create(ProxyType, false, { Owner = playerOwner })
	local lz = Utils.Random(ParadropWaypoints)
	PowerProxy.TargetParatroopers(lz.CenterPosition, Angle.East)
end

SendUnits = function(playerOwner, enter, rally, types, timeInterval)
	local units = Reinforcements.Reinforce(playerOwner, types, { enter.Location }, timeInterval)
	for i = 1, table.getn(units) do
		units[i].AttackMove(rally.Location)
	end
end

SendWaterUnits = function(playerOwner, types, enter, rally, exit)
	exit = exit or enter
	local units = Reinforcements.ReinforceWithTransport(playerOwner, "lst",
			types, { enter.Location, rally.Location }, { exit.Location })[2]
end

WorldLoaded = function()
	GoodGuy = Player.GetPlayer("GoodGuy")
	Greece = Player.GetPlayer("Greece")
	Allies = Player.GetPlayer("Allies")

	USSR = Player.GetPlayer("USSR")
	Spain = Player.GetPlayer("Spain")


	Trigger.AfterDelay(DateTime.Seconds(35), function()
		SendUnits(Spain, SpainInvEnter, SpainInvRally, SpainReinforceUnits, 0)
		local cam = Actor.Create("Camera", true, { Owner = GoodGuy, Location = bgInvCam1.Location })
		Trigger.AfterDelay(DateTime.Seconds(19), function()
			local cam = Actor.Create("Camera", true, { Owner = GoodGuy, Location = bgInvCam2.Location })
		end)
	end)

	InitObjectives(GoodGuy)
	DestroyBaddiesObj = AddPrimaryObjective(GoodGuy, "destroy-baddies")
	NoLetHeliObj = AddSecondaryObjective(GoodGuy, "no-let-heli")

	BeatAllies = AddPrimaryObjective(USSR, "")

	Trigger.AfterDelay(DateTime.Seconds(5), function()
		Media.DisplayMessage(UserInterface.Translate("s-1"))
		ParadropUnits(GoodGuy)
		ParadropUnits(GoodGuy)
		ParadropUnits(Greece)
		ParadropUnits(Greece)
		Trigger.AfterDelay(DateTime.Seconds(25), function()
			Media.DisplayMessage(UserInterface.Translate("s-2"))
			SendWaterUnits(GoodGuy, WaterTanks, WaterEnter, Land1)
			Trigger.AfterDelay(DateTime.Seconds(3), function()
				SendWaterUnits(GoodGuy, WaterTanks, WaterEnter, Land2)
				Trigger.AfterDelay(DateTime.Seconds(3), function()
					SendWaterUnits(Greece, WaterTanks, WaterEnter, Land3)
					Trigger.AfterDelay(DateTime.Seconds(3), function()
						SendWaterUnits(Greece, WaterTanks, WaterEnter, Land4)
						Media.DisplayMessage(UserInterface.Translate("s-3"))
					end)
				end)
			end)
		end)
	end)

	StartTimerFunction()
end