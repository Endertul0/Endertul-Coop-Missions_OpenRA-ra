---Create a table full of cpos between (x1, y1) and (x2, y2)
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return table
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
---@param waypointTable table
Paradrop = function(playerOwner, waypointTable, proxy, angle)
    local PowerProxy = Actor.Create(proxy, false, { Owner = playerOwner })
    local lz = Utils.Random(waypointTable)
    PowerProxy.TargetParatroopers(lz.CenterPosition, angle)
end

---@param owner player
---@param proxy string
---@param pos wpos
Parabomb = function(owner, proxy, pos, angle)
    angle = angle or Angle.NorthEast
    local power = Actor.Create(proxy, false, { Owner = owner })
    power.TargetAirstrike(pos, angle)
end

---@param playerOwner player
---@param enter cpos
---@param rally cpos
---@param types table
---@param timeinterval number
---@param repeatAfter number
---@return table
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

-- Top-level unit name constants
TanyaStr = "tanya"
Hint = "hint"
ChinookStr = "tran"
WaterTranStr = "lst"

LstLZ = CreateCposTable(53, 19, 55, 21)
BvkDestroyBridge = CreateCposTable(67, 88, 69, 93)
JoinChaseArea = CreateCposTable(58, 89, 62, 89)

PowerGrid = { app1, app2, app3, app4, app5 }
Syrd1CaptureFlares = { FComFlare1, SyrdFlare1, SyrdFlare2 }
BalatovikGaurds1 = { bG1, bG2, bG3 }
BalatovikGaurds2 = { bG4, bG5, bG6, bG7 }
BvkAndGuards = { bG1, bG2, bG3, bG4, bG5, bG6, bG7, BvkUnit }
BvkBaseLarge = { b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18, b19, b20, b21, b22 }
BvkBaseSmall = { b23, b24, b25, b26, b27, b28, b29, b30, b31 }
BvkBaseLargeCams = { c1, c2, c3, c4, c5 }
BvkBaseSmallCams = { c6, c7, c8, c9, c10, c11 }
aagns = { aagn1, aagn2 }
spiesInLst1 = { false, false }
producedYet = false
StekInfiltrated = false
bombsAway = false
CamExposer = nil

AllAngles = {
    Angle.North,
    Angle.NorthEast,
    Angle.East,
    Angle.SouthEast,
    Angle.South,
    Angle.SouthWest,
    Angle.West,
    Angle.NorthWest
}

ParadropType = "powerproxy.paratroopers"
ParabombType = "powerproxy.parabombs"

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
        a.Move(BEvacTo.Location)
        if not (a == Map.NamedActor("BvkUnit")) then
            a.Move(GuardLoc.Location)
        end
        Trigger.AfterDelay(DateTime.Seconds(15), function()
            Utils.Do(Utils.Concat(BvkBaseLargeCams, BvkBaseSmallCams), function(camera)
                Trigger.AfterDelay(Utils.RandomInteger(0, 35), function()
                    camera.Owner = Allies
                end)
            end)
            CamExposer = nil
        end)
    end)
end

Tick = function()
    if CamExposer ~= nil then
        local c = Actor.Create("camera.paradrop", true, { Owner = Allies, Location = CamExposer.Location })
        Trigger.AfterDelay(1, function()
            c.Destroy()
        end)
    end
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

    -- Setup objectives
    Utils.Do(Humans, function(player)
        if player then
            InfiltrateStekObj = AddPrimaryObjective(player, "infiltrate-stek")
            EliminateBalatovikObj = AddPrimaryObjective(player, "eliminate-balatovik")
            DestroyBasesObj = AddPrimaryObjective(player, "destroy-bases")
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

    -- Complete obj on all killed
    Trigger.OnAllKilledOrCaptured(PowerGrid, function()
        Utils.Do(Humans, function(player)
            player.MarkCompletedObjective(PowerGridObj)
        end)
    end)

    -- Fail obj on killed
    Trigger.OnKilled(StekObjBuilding, function()
        Utils.Do(Humans, function(player)
            player.MarkFailedObjective(InfiltrateStekObj)
        end)
    end)

    -- When bvk + guards go to brdge proximity trigger
    Trigger.OnEnteredFootprint(BvkDestroyBridge, function(a)
        if not bombsAway and a.Owner == BalatovikHO then
            bombsAway = true
            for i = 1, 11 do
                Trigger.AfterDelay(Utils.RandomInteger(0, 60), function()
                    Parabomb(Balatovik, ParabombType, BvkBridgeAttack.CenterPosition, Angle.NorthEast)
                end)
            end
            SendUnits(Allies, CPos.New(57, 96), BvkUnit.Location,
                    { "e1", "e1", "e1", "e3", "e3", "e2" }, 0, -1)
            local c = Actor.Create("camera.paradrop", true, { Owner = Allies, Location = BvkBridgeAttack.Location })
            Trigger.AfterDelay(DateTime.Seconds(10), function()
                c.Destroy()
            end)
            Media.PlaySound("alert.aud")
        end
    end)

    -- When spy infiltrates stek, start bvk escape
    Trigger.OnInfiltrated(StekObjBuilding, function(self, unit)
        if not StekInfiltrated then
            StekInfiltrated = true
            Utils.Do(Humans, function(player)
                player.MarkCompletedObjective(InfiltrateStekObj)
            end)
            Camera.Position = BvkUnit.CenterPosition

            local USSRBldgs = Utils.Where(Map.ActorsInWorld, function(bdg)
                return bdg.Owner == USSR and bdg.HasProperty("StartBuildingRepairs")
            end)
            Utils.Do(USSRBldgs, function(a)
                local bombAngle = Utils.Random(AllAngles)
                Parabomb(Allies, ParabombType, a.CenterPosition, bombAngle)
            end)
            Media.DisplayMessage(UserInterface.Translate("what-that"), UserInterface.Translate(TanyaStr))
            Trigger.AfterDelay(DateTime.Seconds(2), function()
                Camera.Position = aagn1.CenterPosition
                Utils.Do(BalatovikGaurds1, function(a)
                    a.Attack(aagns[1])
                end)
                Utils.Do(BalatovikGaurds2, function(a)
                    a.Attack(aagns[2])
                end)
                CamExposer = BvkUnit
                Trigger.OnAllKilledOrCaptured(aagns, function()
                    EvacuateBalatovik(BEvacTo)
                    local alliesTranUnits = SendTransport(Allies, "lst", { "e1", "e1", "e1", "e3", "e3", "e2" },
                            BalatovikChaseEnter.Location, BalatovikChaseLand.Location, BalatovikChaseEnter.Location)
                    Trigger.AfterDelay(DateTime.Seconds(8), function()
                        Utils.Do(alliesTranUnits, function(a)
                            a.AttackMove(CPos.New(68, 90))
                        end)
                    end)

                    Media.DisplayMessage(UserInterface.Translate("come-on"), UserInterface.Translate(TanyaStr))

                    Utils.Do(Syrd1CaptureFlares, function(a)
                        a.Destroy()
                    end)
                    Utils.Do(Humans, function(player)
                        Media.PlaySpeechNotification(player, "BuildingInfiltrated")
                    end)
                    SyrdFcom1.Owner = Allies
                    Syrd1.Owner = Allies1
                    Syrd2.Owner = Allies2
                    Syrd1.Produce("tca")
                    Syrd2.Produce("tca")

                    Media.DisplayMessage(UserInterface.Translate("chase"), UserInterface.Translate(Hint))
                end)
            end)
        end
    end)

    -- When spy gets to landing zone
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
                MoveAndUnloadTransport(SpyLst1, UnloadPoint1.Location, { WE1, WE2, WE3, WE4, WEE })
                Utils.Do(Humans, function(player)
                    player.MarkCompletedObjective(LstFlareObj)
                end)
            end
        end)
    end)

    -- On large base killed
    Trigger.OnAllKilled(BvkBaseLarge, function()
        Utils.Do(Humans, function(player)
            player.MarkCompletedObjective(DestroyBasesObj)
        end)
        Camera.Position = SBSAR1.CenterPosition
        local units = SendTransport(Allies, "lst", { "e3", "e3", "e3", "e3", "e3",
                                                     "e2", "e2", "e2", "e2", "e2", "e3", "e3", "e3", "e3", "e3",
                                                     "e2", "e2", "e2", "e2", "e2" }, WEE.Location, SBSAI.Location, WEE.Location)
        Trigger.AfterDelay(DateTime.Seconds(4), function()
            Utils.Do(units, function(a)
                a.AttackMove(SBSAR1.Location)
                a.AttackMove(SBSAR2.Location)
                a.AttackMove(SBSAR3.Location)
                a.AttackMove(SBSAR4.Location)
            end)
        end)

        Trigger.OnAllKilled(BvkBaseSmall, function()
            Trigger.OnKilled(BvkUnit, function()
                Utils.Do(Humans, function(player)
                    player.MarkCompletedObjective(EliminateBalatovikObj)
                end)
            end)

            local units2 = SendTransport(Allies, "tran", { "e1", "e1", "e1", "e1", "e1", "e1", "e1", "e1", "e1" },
                    InsertionEnter.Location, InsertionLand.Location, InsertionEnter.Location)
            Trigger.AfterDelay(DateTime.Seconds(8), function()
                Utils.Do(units2, function(a)
                    a.AttackMove(GuardLoc.Location)
                    a.AttackMove(BEvacTo.Location)
                end)
            end)
        end)
    end)
end