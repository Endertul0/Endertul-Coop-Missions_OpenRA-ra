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