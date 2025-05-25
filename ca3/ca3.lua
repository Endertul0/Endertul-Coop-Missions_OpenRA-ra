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

-- Top-level unit name constants
TanyaStr = "tanya"
Hint = "hint"
ChinookStr = "tran"
WaterTranStr = "lst"

StekCaptureLoc = CreateCposArray(34, 72, 40, 77)
Syrd1CaptureLoc = CreateCposArray(26, 24, 30, 29)
LstLZ = CreateCposArray(53, 19, 55, 21)
BvkDestroyBridge = CreateCposArray(67, 88, 69, 93)

PowerGrid = { app1, app2, app3, app4, app5 }
Syrd1CaptureFlares = { FComFlare1, SyrdFlare1, SyrdFlare2 }
BalatovikGaurds1 = { bG1, bG2, bG3 }
BalatovikGaurds2 = { bG4, bG5, bG6, bG7 }
BvkAndGuards = { bG1, bG2, bG3, bG4, bG5, bG6, bG7, BvkUnit }
aagns = { aagn1, aagn2 }
spiesInLst1 = { false, false }
producedYet = false
StekInfiltrated = false
bombsAway = false

ParadropType = "powerproxy.paratroopers"
ParabombType = "powerproxy.parabombs"

---Create a table full of cpos between (x1, y1) and (x2, y2)
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
CreateCposTable = function(x1, y1, x2, y2)
    local comTable = {}
    for x = x1, x2 do
        for y = y1, y2 do
            table.insert(comTable, CPos.New(x, y))
        end
    end
    return comTable
end

---@param playerOwner player
---@param wayointTable table
ParadropUnits = function(playerOwner, wayointTable, proxy, angle)
    local PowerProxy = Actor.Create(proxy, false, { Owner = playerOwner })
    local lz = Utils.Random(wayointTable)
    PowerProxy.TargetParatroopers(lz.CenterPosition, angle)
end

---@param playerOwner player
---@param enter cpos
---@param rally cpos
---@param types table
---@param timeinterval number
---@param repeatAfter number
SendUnits = function(playerOwner, enter, rally, types, timeinterval, repeatAfter)
    repeatAfter = repeatAfter or -1
    local units = Reinforcements.Reinforce(playerOwner, types, { enter }, timeinterval)
    Utils.Do(units, function(a)
        a.AttackMove(rally)
    end)
    if not (repeatAfter == -1) then
        Trigger.AfterDelay(DateTime.Seconds(repeatAfter), function()
            SendUnits(playerOwner, enter, rally, types, timeinterval, repeatAfter)
        end)
    end
    return units
end

---@param playerOwner player
---@param transType string
---@param types table
---@param enter cpos
---@param rally cpos
---@param exit cpos
---@return table
SendTransport = function(playerOwner, transType, types, enter, rally, exit, repeatAfter)
    exit = exit or enter
    repeatAfter = repeatAfter or -1
    local units = Reinforcements.ReinforceWithTransport(playerOwner, transType,
            types, { enter, rally }, { exit })[2]
    if not (repeatAfter == -1) then
        Trigger.AfterDelay(DateTime.Seconds(repeatAfter), function()
            SendTransport(playerOwner, transType, types, enter, rally, exit, repeatAfter)
        end)
    end
    return units
end

MoveAndUnloadTransport = function(trans, pt, outPath)
    trans.UnloadPassengers(pt)
    trans.Move(outPath[1].Location)
    trans.Move(outPath[2].Location)
    trans.Move(outPath[3].Location)
    trans.Move(outPath[4].Location)
    trans.Move(outPath[5].Location)
    trans.Destroy()
end

EvacuateBalatovik = function(evacTo)
    Utils.Do(BvkAndGuards, function(a)
        a.Move(BvkBridgeAttack.Location)
        Trigger.AfterDelay(DateTime.Seconds(11), function()
            a.Move(BEvacTo.Location)
            if not (a == Map.NamedActor("BvkUnit")) then
                a.Move(GuardLoc.Location)
            end
        end)
    end)
end

WorldLoaded = function()
    -- SETUP PLAYERS & OTHER INITIAL THINGS
    Allies = Player.GetPlayer("Allies")
    Allies1 = Player.GetPlayer("Allies1")
    Allies2 = Player.GetPlayer("Allies2")

    USSR = Player.GetPlayer("USSR")
    Balatovik = Player.GetPlayer("Balatovik")
    BalatovikHO = Player.GetPlayer("BalatovikHO")

    Humans = { Allies1, Allies2 }

    Spy1 = Map.NamedActor("A1Spy")
    Spy2 = Map.NamedActor("A2Spy")

    Camera.Position = HeliFlare.CenterPosition
    InitObjectives(Allies1)

    Utils.Do(Humans, function(player)
        if player then
            InfiltrateStekObj = AddPrimaryObjective(player, "infiltrate-stek")
            EliminateBalatovikObj = AddPrimaryObjective(player, "eliminate-balatovik")
            LstFlareObj = AddSecondaryObjective(player, "get-flare")
            PowerGridObj = AddSecondaryObjective(player, "power-down")
        end
    end)

    -- USE FUNCTIONS AND TRIGGERS
    Trigger.AfterDelay(DateTime.Seconds(4), function()
        Media.DisplayMessage(UserInterface.Translate("make-sure"), UserInterface.Translate(TanyaStr))
        Trigger.AfterDelay(DateTime.Seconds(4), function()
            Media.DisplayMessage(UserInterface.Translate("disguise-spy"), UserInterface.Translate("spy"))
        end)
    end)

    Trigger.AfterDelay(DateTime.Seconds(1), function()
    --Trigger.AfterDelay(DateTime.Seconds(25), function()
        Media.DisplayMessage(UserInterface.Translate("what-that"), UserInterface.Translate(TanyaStr))
        Trigger.AfterDelay(DateTime.Seconds(2), function()
            Camera.Position = BEC1.CenterPosition
            Utils.Do(BalatovikGaurds1, function(a)
                a.Attack(aagns[1])
            end)
            Utils.Do(BalatovikGaurds2, function(a)
                a.Attack(aagns[2])
            end)
            Trigger.OnAllKilledOrCaptured(aagns, function(a)
                EvacuateBalatovik(BEvacTo)
                Media.DisplayMessage(UserInterface.Translate("come-on"), UserInterface.Translate(TanyaStr))
                Utils.Do(Syrd1CaptureFlares, function(a)
                    a.Destroy()
                end)
                Utils.Do(Humans, function(player)
                    Media.PlaySpeechNotification(player, "BuildingInfiltrated")
                end)
                SyrdFcom1.Owner = Allies
                Camera.Position = SyrdFcom1.CenterPosition
                Syrd1.Owner = Allies1
                Syrd2.Owner = Allies2
                Syrd1.Produce("tca")
                Syrd2.Produce("tca")
                Media.DisplayMessage(UserInterface.Translate("chase"), UserInterface.Translate(Hint))
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

    Trigger.OnEnteredFootprint(BvkDestroyBridge, function(unit)
        if not bombsAway then
            bombsAway = true
            local proxy = Actor.Create("powerproxy.parabombs", false, { Owner = Balatovik })
            for i = 1, 10 do
                proxy.TargetAirstrike(BvkBridgeAttack.CenterPosition, Angle.NorthEast)
            end
            Trigger.AfterDelay(DateTime.Seconds(3), function()
                proxy.Destroy()
            end)
            Media.PlaySound("alert.aud")
        end
    end)

    Trigger.OnEnteredFootprint(StekCaptureLoc, function(unit)
        if unit == Spy1 or unit == Spy2 and not StekInfiltrated then
            StekInfiltrated = true
            Utils.Do(Humans, function(player)
                player.MarkCompletedObjective(InfiltrateStekObj)
            end)
            Media.DisplayMessage(UserInterface.Translate("get-balatovik"), UserInterface.Translate(TanyaStr))
            Camera.Position = BalatovFlare.CenterPosition

            local USSRbldgs = Utils.Where(Map.ActorsInWorld, function(self)
                return self.Owner == USSR and self.HasProperty("StartBuildingRepairs")
            end)
            Utils.Do(USSRbldgs, function(a)
                --SupportPowerTargeted(Allies, ParabombType, { a })
            end)
        else
            if unit.Owner == Allies1 or unit.Owner == Allies2 then
                Media.DisplayMessage(UserInterface.Translate("get-spy"), UserInterface.Translate(Hint))
            end
        end
    end)

    Trigger.OnEnteredFootprint(Syrd1CaptureLoc, function(unit)
        if unit == Spy1 or unit == Spy2 then
            if Allies1.IsObjectiveCompleted(InfiltrateStekObj) and not producedYet then
                producedYet = true
                Trigger.AfterDelay(DateTime.Seconds(1), function()
                    Media.DisplayMessage(UserInterface.Translate("make-cruiser"), UserInterface.Translate(TanyaStr))
                    Trigger.AfterDelay(DateTime.Seconds(1), function()
                        Media.DisplayMessage(UserInterface.Translate("made-cruiser"), UserInterface.Translate(TanyaStr))
                    end)
                end)
            else
                Media.DisplayMessage(UserInterface.Translate("stek-first"), UserInterface.Translate(TanyaStr))
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
                MoveAndUnloadTransport(SpyLst1, UnloadPoint1.Location, {WE1, WE2, WE3, WE4, WEE})
                Utils.Do(Humans, function(player)
                    player.MarkCompletedObjective(LstFlareObj)
                end)
            end
        end)
    end)


    
end