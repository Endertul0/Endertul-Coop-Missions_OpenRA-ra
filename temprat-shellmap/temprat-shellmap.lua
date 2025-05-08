ProducedUnitTypes = {
    { factory = AB1, types = { "e1", "e3" } },
    { factory = AB2, types = { "e1", "e3" } },
    { factory = SB1, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
    { factory = SB2, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
    { factory = SB3, types = { "dog", "e1", "e2", "e3", "e4", "shok" } },
    { factory = AWF1, types = { "jeep", "1tnk", "2tnk", "arty", "ctnk" } },
    { factory = SWF1, types = { "3tnk", "4tnk", "v2rl", "ttnk", "apc" } }
}

BindActorTriggers = function(a)
    if a.HasProperty("Hunt") then
        if a.Owner == Allies then
            Trigger.OnIdle(a, function(a)
                if a.IsInWorld then
                    a.AttackMove(SB2.Location)
                end
            end)
        elseif a.Owner == Soviets then
            Trigger.OnIdle(a, function(a)
                if a.IsInWorld then
                    a.AttackMove(AB2.Location)
                end
            end)
        else
            Trigger.OnIdle(a, function(a)
                if a.IsInWorld then
                    a.AttackMove(AB2.Location)
                end
            end)
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
Speed = 2

Tick = function()
    Ticks = Ticks + 1

    local t = (Ticks + 45) % (360 * Speed) * (math.pi / 180) / Speed;
    Camera.Position = ViewportOrigin + WVec.New(19200 * math.sin(t), 20480 * math.cos(t), 0)
end

ProduceUnits = function(t)
    local factory = t.factory
    if not factory.IsDead then
        local unitType = t.types[Utils.RandomInteger(1, #t.types + 1)]
        factory.Wait(Actor.BuildTime(unitType) / 30)
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
end