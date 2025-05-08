---@param x1 int
---@param y1 int
---@param x2 int
---@param y2 int
CreateCposTable = function(x1, y1, x2, y2)
    local comTable = {}
    for x = x1, x2 do
        for y = y1, y2 do
            table.insert(comTable, CPos.New(x, y))
        end
    end
    return comTable
end

---@param playerOwner Player
---@param wayointTable table
ParadropUnits = function(playerOwner, wayointTable)
    local PowerProxy = Actor.Create(ProxyType, false, { Owner = playerOwner })
    local lz = Utils.Random(wayointTable)
    PowerProxy.TargetParatroopers(lz.CenterPosition, Angle.East)
end

---@param playerOwner Player
---@param enter Waypoint
---@param rally Waypoint
---@param types table
---@param timeInterval int
SendUnits = function(playerOwner, enter, rally, types, timeInterval)
    local units = Reinforcements.Reinforce(playerOwner, types, { enter.Location }, timeInterval)
    Utils.Do(units, function(a)
        a.AttackMove(rally)
    end)
end

---@param playerOwner Player
---@param types table
---@param enter Waypoint
---@param rally Waypoint
---@param exit Waypoint
---@return unitTable
SendWaterUnits = function(playerOwner, types, enter, rally, exit)
    exit = exit or enter
    local units = Reinforcements.ReinforceWithTransport(playerOwner, "lst",
            types, { enter.Location, rally.Location }, { exit.Location })[2]
    return units
end
