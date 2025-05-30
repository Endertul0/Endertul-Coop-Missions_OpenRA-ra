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

CamLock = nil
ToX4 = { CPos.New(8, 78) }
ToChoice2 = { CPos.New(9, 77) }
ToChoice3 = { CPos.New(31, 76) }
ToX1 = { CPos.New(32, 77) }
ToX2 = { CPos.New(33, 61) }
ToX3 = { CPos.New(34, 62) }

AtX1 = { X1.Location }
AtX2 = { X2.Location }
AtX3 = { X3.Location }
AtX4 = { X4.Location }

Tick = function()
    if CamLock ~= nil and not (CamLock.IsDead) then
        Camera.Position = CamLock.CenterPosition
    end
end

---@param loc cpos
---@param type string
---@param angle wangle
CShift = function(loc, type, angle)
    local cells = { loc }
    local units = { }
    for i = 1, #cells do
        local unit = Actor.Create(type, true, { Owner = Spain, Facing = angle })
        units[unit] = cells[i]
    end
    Csphere.Chronoshift(units)
end

WorldLoaded = function()
    Allies = Player.GetPlayer("Allies")
    Spain = Player.GetPlayer("Spain")
    Camera.Position = CamStart.CenterPosition

    Trigger.OnEnteredFootprint(ToX1, function(a, id)
        a.Move(X1.Location)
    end)
    Trigger.OnEnteredFootprint(ToX2, function(a, id)
        a.Move(X2.Location)
    end)
    Trigger.OnEnteredFootprint(ToX3, function(a, id)
        a.Move(X3.Location)
    end)
    Trigger.OnEnteredFootprint(ToX4, function(a, id)
        a.Move(X4.Location)
    end)


    Trigger.OnEnteredFootprint(ToChoice2, function(a, id)
        a.Move(Choice2.Location)
    end)
    Trigger.OnEnteredFootprint(ToChoice3, function(a, id)
        a.Move(Choice3.Location)
    end)


    Trigger.OnEnteredFootprint(AtX1, function(a, id)
        CShift(CPos.New(71, 84), "arty", Angle.North)
        CShift(CPos.New(78, 78), "arty", Angle.West)
    end)
    Trigger.OnEnteredFootprint(AtX2, function(a, id)
        CShift(CPos.New(30, 49), "3tnk", Angle.East)
        CShift(CPos.New(35, 51), "1tnk", Angle.NorthWest)
    end)
    Trigger.OnEnteredFootprint(AtX3, function(a, id)
        CShift(CPos.New(57, 69), "arty", Angle.NorthEast)
        CShift(CPos.New(59, 62), "apc", Angle.SouthEast)
    end)
    Trigger.OnEnteredFootprint(AtX4, function(a, id)
        SendUnits(Spain, CamStart.Location, X4.Location, { "jeep" }, 0, -1)
    end)

    CamLock = AUnit
    AUnit.MoveIntoWorld(Choice1.Location)
end