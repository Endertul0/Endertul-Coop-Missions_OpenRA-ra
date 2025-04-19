
UDefenses1 = { UHbox1, UHbox2, UGun1, UGun2 }
UPwrGrid = { UPwrGrid1, UPwrGrid2, UPwrGrid3, UPwrGrid4, UPwrGrid5, UPwrGrid6 }
UAflds = { UAfld1, UAfld2, UAfld3, UAfld4, UAfld5, UAfld6 }

Jammers = { MRJ1, MRJ2, MRJ3, MRJ4 }
SpainSubs = { SpainBlock1, SpainBlock2, SpainBlock3 }

WaterTypes = { "e1", "e1", "e1", "e3", "e3", "e2", "e1", "e1", "e1", "e3", "e3", "e2" }
TanyaTypes = { "e7" }

StartTimer = false
TimerColor = Player.GetPlayer("USSR").Color
EndTimerColor = Player.GetPlayer("Spain").Color
TimerTicks = DateTime.Minutes(1)
Ticked = TimerTicks
once1 = false

WaterTransportType = "lst.unselectable.unloadonly"
AirTransportType = "tran.unselectable.unloadonly"

StartTimerFunction = function()
    StartTimer = true
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

    if HoldOut.HasNoRequiredUnits() and not once1 then
        once1 = true
        Media.DisplayMessage(UserInterface.Translate("getting-away"), UserInterface.Translate("tanya"))

        Trigger.AfterDelay(DateTime.Seconds(10), function()
            Utils.Do(Humans, function(player)
                if player then
                    player.MarkCompletedObjective(DestroyBaddiesObj)
                end
            end)
        end)
    end
end

SendWaterUnits = function()
    c1path = { WaterWayEnter.Location, WaterWay1.Location, CP1.Location }
    c2path = { WaterWayEnter.Location, WaterWay1.Location, CP2.Location }
    local crusier1 = Reinforcements.Reinforce(Allies, { "ca.tesla" }, c1path)
    local crusier2 = Reinforcements.Reinforce(Allies, { "ca.tesla" }, c2path)
    local cruiserCam1 = Actor.Create("Camera", true, { Owner = Allies, Location = CruiserCam.Location })
    local transportPath1 = { WaterWayEnter.Location, WaterWay1.Location, WaterWay2.Location, Unload1.Location }
    local transportPath2 = { WaterWayEnter.Location, WaterWay1.Location, WaterWay2.Location, Unload2.Location }
    local transportPath3 = { WaterWayEnter.Location, WaterWay1.Location, WaterWay2.Location, Unload2.Location }
    Media.DisplayMessage(UserInterface.Translate("almost-there"), UserInterface.Translate("tanya"))
    Trigger.AfterDelay(DateTime.Seconds(14), function()
        local transport1 = Reinforcements.ReinforceWithTransport(Allies1, WaterTransportType,
                WaterTypes, transportPath1, { WaterWayEnter.Location })[2]
        Trigger.AfterDelay(DateTime.Seconds(16), function()
            Utils.Do(transport1, function(unit)
                unit.Move(AAtek.Location)
            end)
        end)
        Trigger.AfterDelay(DateTime.Seconds(4), function()
            local transport2 = Reinforcements.ReinforceWithTransport(Allies2, WaterTransportType,
                    WaterTypes, transportPath2, { WaterWayEnter.Location } )[2]
            Trigger.AfterDelay(DateTime.Seconds(16), function()
                Utils.Do(transport2, function(unit)
                    unit.Move(AAtek.Location)
                end)
            end)
            Trigger.AfterDelay(DateTime.Seconds(4), function()
                local tanyaTransport = Reinforcements.ReinforceWithTransport(Allies, AirTransportType,
                        TanyaTypes, transportPath3, { WaterWayEnter.Location } )[2]
                Trigger.AfterDelay(DateTime.Seconds(16), function()
                    Media.DisplayMessage(UserInterface.Translate("all-handled"), UserInterface.Translate("tanya"))
                    Utils.Do(tanyaTransport, function(unit)
                        unit.Move(AAtek.Location)
                    end)
                end)
                Media.DisplayMessage(UserInterface.Translate("nice-job"), UserInterface.Translate("tanya"))
            end)
        end)
    end)
end

WorldLoaded = function()
    -- Define players
    Neutral = Player.GetPlayer("Neutral")
    Spain = Player.GetPlayer("Spain")

    Allies = Player.GetPlayer("Allies")
    Allies1 = Player.GetPlayer("Allies1")
    Allies2 = Player.GetPlayer("Allies2")

    USSR = Player.GetPlayer("USSR")
    HoldOut = Player.GetPlayer("HoldOut")

    Humans = { Allies1, Allies2 }
    Utils.Do(Humans, function(player)
        if player and player.IsLocalPlayer then
            InitObjectives(player)
            TextColor = player.Color
        end
    end)

    Utils.Do(Humans, function(player)
        if player then
            SaveDomeObj = AddPrimaryObjective(player, "save-dome")
            DestroyDefenses1Obj = AddSecondaryObjective(player, "destroy-defenses-1")
        end
    end)
    BeatAllies = AddPrimaryObjective(USSR, "")

    -- Use functions
    Trigger.OnAllKilledOrCaptured(Jammers, function()
        if not ADomeJammed.IsDead then
            Utils.Do(Humans, function(player)
                if player then
                    DestroyBaddiesObj = AddPrimaryObjective(player, "destroy-baddies")
                    Trigger.AfterDelay(DateTime.Seconds(1), function()
                        player.MarkCompletedObjective(SaveDomeObj)
                    end)

                    local footholdCam = Actor.Create("Camera", true, { Owner = Allies, Location = FCPos.Location })
                    Trigger.AfterDelay(DateTime.Seconds(1), footholdCam.Destroy)
                    Trigger.AfterDelay(DateTime.Seconds(1), function()
                        SendWaterUnits()
                    end)
                end
            end)
        end
    end)

    Trigger.OnAllKilledOrCaptured(UDefenses1, function()
        Utils.Do(Humans, function(player)
            if player then
                player.MarkCompletedObjective(DestroyDefenses1Obj)
                DestroyPowerObj = AddSecondaryObjective(player, "destroy-power")
                DestroyAfldObj = AddSecondaryObjective(player, "destroy-aflds")
                local powerCam1 = Actor.Create("Camera.paradrop", true, { Owner = Allies, Location = UPCP1.Location })
                local powerCam2 = Actor.Create("Camera.paradrop", true, { Owner = Allies, Location = UPCP2.Location })
                local afldCam = Actor.Create("Camera.paradrop", true, { Owner = Allies, Location = UACP.Location })
                local domeCam = Actor.Create("Camera.paradrop", true, { Owner = Allies, Location = domeCamPos.Location })
                Trigger.AfterDelay(DateTime.Seconds(1), powerCam1.Destroy)
                Trigger.AfterDelay(DateTime.Seconds(1), powerCam2.Destroy)
                Trigger.AfterDelay(DateTime.Seconds(1), afldCam.Destroy)
                Trigger.AfterDelay(DateTime.Seconds(1), domeCam.Destroy)
            end
        end)
    end)

    Trigger.OnAllKilledOrCaptured(UPwrGrid, function()
        Utils.Do(Humans, function(player)
            if player then
                player.MarkCompletedObjective(DestroyPowerObj)
            end
        end)
    end)

    Trigger.OnAllKilledOrCaptured(UAflds, function()
        Utils.Do(Humans, function(player)
            if player then
                player.MarkCompletedObjective(DestroyAfldObj)
            end
        end)
    end)


end