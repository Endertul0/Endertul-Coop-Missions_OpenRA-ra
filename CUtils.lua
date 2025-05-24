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
ParadropUnits = function(playerOwner, wayointTable, proxy, angle)
    local PowerProxy = Actor.Create(proxy, false, { Owner = playerOwner })
    local lz = Utils.Random(wayointTable)
    PowerProxy.TargetParatroopers(lz.CenterPosition, angle)
end

---@param playerOwner Player
---@param enter Waypoint
---@param rally Waypoint
---@param types table
---@param timeInterval int
---@param repeatAfter int
SendUnits = function(playerOwner, enter, rally, types, timeInterval, repeatAfter)
    repeatAfter = repeatAfter or -1
    local units = Reinforcements.Reinforce(playerOwner, types, { enter.Location }, timeInterval)
    Utils.Do(units, function(a)
        a.AttackMove(rally.Location)
    end)
    if not (repeatAfter == -1) then
        Trigger.AfterDelay(DateTime.Seconds(repeatAfter), function()
            SendUnits(playerOwner, enter, rally, types, timeInterval, repeatAfter)
        end)
    end
    return units
end

---@param playerOwner Player
---@param transType string
---@param types table
---@param enter Waypoint
---@param rally Waypoint
---@param exit Waypoint
---@return unitTable
SendTransport = function(playerOwner, transType, types, enter, rally, exit, repeatAfter)
    exit = exit or enter
    repeatAfter = repeatAfter or -1
    local units = Reinforcements.ReinforceWithTransport(playerOwner, transType,
            types, { enter.Location, rally.Location }, { exit.Location })[2]
    if not (repeatAfter == -1) then
        Trigger.AfterDelay(DateTime.Seconds(repeatAfter), function()
            SendUnits(playerOwner, enter, rally, types, timeInterval, repeatAfter)
        end)
    end
    return units
end