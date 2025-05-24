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

ProducedUnitTypes = {
    { factory = AB1, types = { "e1", "e3" } },
    { factory = AB2, types = { "e1", "e3" } },
    { factory = AB3, types = { "e1", "e3" } },

    { factory = SB1, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
    { factory = SB2, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
    { factory = SB3, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },

    { factory = AWF1, types = { "jeep", "1tnk", "2tnk", "arty", "ctnk" } },
    { factory = AWF2, types = { "jeep", "1tnk", "2tnk", "arty", "ctnk" } },

    { factory = SWF1, types = { "3tnk", "4tnk", "v2rl", "ttnk", "apc" } },
    { factory = SWF2, types = { "3tnk", "4tnk", "v2rl", "ttnk", "apc" } },

    { factory = AH1, types = { "tran", "mh60", "mh60", "mh60", "heli" } },
    { factory = AH2, types = { "tran", "mh60", "mh60", "mh60", "heli" } },

    { factory = SA1, types = { "yak", "yak", "yak", "yak", "mig" } },
    { factory = SA2, types = { "yak", "yak", "yak", "yak", "mig" } }
}

SpainBridgeTypes = { "e1", "e1", "e1", "e3", "e3", "e2" }

AlliesTranPts = CreateCposTable(31, 55, 35, 60)
SovietsTranPts = CreateCposTable(76, 45, 81, 52)
SpainTranPts = CreateCposTable(50, 50, 58, 54)

SpainBridgeinterval = 50
SpainTranInterval = SpainBridgeinterval*2 / 3

BindActorTriggers = function(a)
    if a.HasProperty("Hunt") then
        if a.Owner == Allies then
            Trigger.OnIdle(a, function(a)
                if a.IsInWorld then
                    a.AttackMove(SoCePo.Location)
                end
            end)
        elseif a.Owner == Soviets then
            Trigger.OnIdle(a, function(a)
                if a.IsInWorld then
                    a.AttackMove(AlCePo.Location)
                end
            end)
        else
            Trigger.OnIdle(a, function(a)
                if a.IsInWorld then
                    a.AttackMove(snr.Location)
                end
            end)
        end
    end

    if a.Type == "tran" then
        if a.Owner == Allies then
            local sel = Utils.Random(AlliesTranPts)
            a.UnloadPassengers(sel)
            a.Move(AlliesTExit.Location)
            a.Destroy()
        elseif a.Owner == Soviets then
            local sel = Utils.Random(SovietsTranPts)
            a.UnloadPassengers(sel)
            a.Move(SovietSTExit.Location)
            a.Destroy()
        end
    end

    if a.HasProperty("HasPassengers") then
        Trigger.OnPassengerExited(a, function(t, p)
            BindActorTriggers(p)
        end)

        Trigger.OnDamaged(a, function()
            if a.HasPassengers then
                a.Stop()
                a.UnloadPassengers()
            end
        end)
    end
end

Ticks = 0
Speed = 3

Tick = function()
    Ticks = Ticks + 1

    local t = (Ticks + 45) % (360 * Speed) * (math.pi / 180) / Speed;
    Camera.Position = ViewportOrigin + WVec.New(19200 * math.sin(t), 20480 * math.cos(t), 0)
end

ProduceUnits = function(t)
    local factory = t.factory
    if not factory.IsDead then
        local unitType = t.types[Utils.RandomInteger(1, #t.types + 1)]
        factory.Wait(Actor.BuildTime(unitType))
        factory.Produce(unitType)
        factory.CallFunc(function()
            ProduceUnits(t)
        end)
    end
end

SetupFactories = function()
    Utils.Do(ProducedUnitTypes, function(production)
        Trigger.OnProduction(production.factory, function(_, a)
            BindActorTriggers(a)
        end)
    end)
end

WorldLoaded = function()
    ViewportOrigin = Camera.Position

    Allies = Player.GetPlayer("Allies")
    Soviets = Player.GetPlayer("Soviets")
    Spain = Player.GetPlayer("Spain")

    SetupFactories()

    Utils.Do(ProducedUnitTypes, ProduceUnits)
    Trigger.AfterDelay(DateTime.Seconds(18), function()
        SendUnits(Spain, sae1.Location, AlCePo.Location, SpainBridgeTypes, 1, SpainBridgeinterval)
        SendUnits(Spain, sae2.Location, AlCePo.Location, SpainBridgeTypes, 1, SpainBridgeinterval)
        SendUnits(Spain, sse1.Location, SoCePo.Location, SpainBridgeTypes, 1, SpainBridgeinterval)
        SendUnits(Spain, sse2.Location, SoCePo.Location, SpainBridgeTypes, 1, SpainBridgeinterval)
        SendTransport(Spain, "tran", { "e1", "e1", "e1", "e1",
                                                        "e3", "e3", "e3", "e2" },
                      SpainTranEnter.Location, Utils.Random(SpainTranPts), SpainTranEnter.Location, SpainTranInterval)
    end)
end