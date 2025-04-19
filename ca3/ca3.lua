-- Generates an array (Array = CreateCposArray(x1, y1, x2, y2))
CreateCposArray = function(x1, y1, x2, y2)
    local comArray = {}
    for x = x1, x2 do
        for y = y1, y2 do
            table.insert(comArray, CPos.New(x, y))
        end
    end
    return comArray
end



StekCaptureLoc = CreateCposArray(34, 72, 40, 77)
Syrd1CaptureLoc = CreateCposArray(26, 24, 30, 29)
LstLZ = CreateCposArray(53, 19, 55, 21)

PowerGrid = { app1, app2, app3, app4, app5 }
Syrd1CaptureFlares = { FComFlare1, SyrdFlare1, SyrdFlare2 }
BalatovikGaurds1 = { bG1, bG2, bG3 }
BalatovikGaurds2 = { bG4, bG5, bG6, bG7 }
AAguns = { AAagun1, AAagun2 }
spiesInLst1 = { false, false }
producedYet = false



ParadropUnits = function(playerOwner)
    local PowerProxy = Actor.Create(ProxyType, false, { Owner = playerOwner })
    local lz = Utils.Random(ParadropWaypoints)
    PowerProxy.TargetParatroopers(lz.CenterPosition, Angle.East)
end

SendUnits = function(playerOwner, enter, rally, types, timeInterval)
    local units = Reinforcements.Reinforce(playerOwner, types, { enter.Location }, timeInterval)
    Utils.Do(units, function(a)
        a.AttackMove(rally)
    end)
end

SendWaterUnits = function(playerOwner, types, enter, rally, exit)
    exit = exit or enter
    local units = Reinforcements.ReinforceWithTransport(playerOwner, "lst",
            types, { enter.Location, rally.Location }, { exit.Location })[2]
end

MoveAndUnloadTransport = function(trans, pt)
    trans.UnloadPassengers(pt)
end

WorldLoaded = function()
    Allies = Player.GetPlayer("Allies")
    Allies1 = Player.GetPlayer("Allies1")
    Allies2 = Player.GetPlayer("Allies2")

    Humans = { Allies1, Allies2 }

    Spy1 = Map.NamedActor("A1Spy")
    Spy2 = Map.NamedActor("A2Spy")

    Camera.Position = HeliFlare.CenterPosition

    Media.DisplayMessage(UserInterface.Translate("make-sure"), UserInterface.Translate("tanya"))
    Utils.Do(Humans, function(player)
        if player then
            InfiltrateStekObj = AddPrimaryObjective(player, "infiltrate-stek")
            EliminateBalatovikObj = AddPrimaryObjective(player, "eliminate-balatovik")
            LstFlareObj = AddSecondaryObjective(player, "get-flare")
            PowerGridObj = AddSecondaryObjective(player, "power-down")
        end
    end)

    Trigger.AfterDelay(DateTime.Seconds(4), function()
        Media.DisplayMessage(UserInterface.Translate("disguise-spy"), UserInterface.Translate("spy"))
    end)

    Trigger.AfterDelay(DateTime.Seconds(5), function()
        Media.DisplayMessage(UserInterface.Translate("what-that"), UserInterface.Translate("tanya"))
        Trigger.AfterDelay(DateTime.Seconds(2), function()
            Camera.Position = bGR.CenterPosition
            Utils.Do(BalatovikGaurds1, function(a)
                a.Attack(AAagun1)
            end)
            Utils.Do(BalatovikGaurds2, function(a)
                a.Attack(AAagun2)
            end)
            Trigger.OnAllKilledOrCaptured(AAguns, function()
                Actor.Create("Camera", true, { Owner = Allies, Location = bGR.Location })
            end)
        end)
    end)

    Trigger.OnAllKilledOrCaptured(PowerGrid, function()
        Utils.Do(Humans, function(player)
            player.MarkCompletedObjective(PowerGridObj)
        end)
    end)

    Trigger.OnKilled(StekObjBuilding, function()
        Utils.Do(Humans, function(player)
            player.MarkFailedObjective(InfiltrateStekObj)
        end)
    end)

    Trigger.OnEnteredFootprint(Syrd1CaptureLoc, function(unit)
        if unit == Spy1 or unit == Spy2 then
            if Allies1.IsObjectiveCompleted(InfiltrateStekObj) and not producedYet then
                producedYet = true
                Utils.Do(Syrd1CaptureFlares, function(a)
                    a.Destroy()
                end)
                Utils.Do(Humans, function(player)
                    Media.PlaySpeechNotification(player, "BuildingInfiltrated")
                end)
                SyrdFcom1.Owner = Allies
                Syrd1.Owner = Allies1
                Syrd2.Owner = Allies2
                Trigger.AfterDelay(DateTime.Seconds(1), function()
                    Media.DisplayMessage(UserInterface.Translate("make-cruiser"), UserInterface.Translate("tanya"))
                    Trigger.AfterDelay(DateTime.Seconds(1), function()
                        Syrd1.Produce("tca")
                        Syrd2.Produce("tca")
                        Media.DisplayMessage(UserInterface.Translate("made-cruiser"), UserInterface.Translate("tanya"))
                    end)
                end)
            else
                Media.DisplayMessage(UserInterface.Translate("stek-first"), UserInterface.Translate("tanya"))
            end
        end
    end)

    Trigger.OnEnteredFootprint(LstLZ, function(unit)
        if unit == Spy1 then
            unit.Stop()
            unit.EnterTransport(SpyLst1)
            Trigger.AfterDelay(DateTime.Seconds(1), function()
                spiesInLst1[1] = true
            end)
        elseif unit == Spy2 then
            unit.Stop()
            unit.EnterTransport(SpyLst1)
            Trigger.AfterDelay(DateTime.Seconds(1), function()
                spiesInLst1[2] = true
            end)
        end
        Trigger.AfterDelay(DateTime.Seconds(2), function()
            if spiesInLst1[1] and spiesInLst1[2] then
                MoveAndUnloadTransport(SpyLst1, UnloadPoint1.Location)
                Utils.Do(Humans, function(player)
                    player.MarkCompletedObjective(LstFlareObj)
                end)
            end
        end)
    end)

    Trigger.OnEnteredFootprint(StekCaptureLoc, function(unit)
        if unit == Spy1 or unit == Spy2 then
            Utils.Do(Humans, function(player)
                player.MarkCompletedObjective(InfiltrateStekObj)
            end)
            Media.DisplayMessage(UserInterface.Translate("get-balatovik"), UserInterface.Translate("tanya"))
        else
            if unit.Owner == Allies1 or unit.Owner == Allies2 then
                Media.DisplayMessage(UserInterface.Translate("get-spy"), UserInterface.Translate("hint"))
            end
        end
    end)


    
end