---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return table Returns a table full of `cpos`s between (`x1`, `y1`) and (`x2`, `y2`)
function CreateCposTable(x1, y1, x2, y2)
    local comTable = {}
    for x = x1, x2 do
        for y = y1, y2 do
            table.insert(comTable, CPos.New(x, y))
        end
    end
    return comTable
end

---@param playerOwner player
---@param withinCposTable table Land paratroopers within this area
---@param proxy string
function Paradrop(playerOwner, withinCposTable, angle, proxy)
    angle = angle or Angle.NorthEast
    proxy = proxy or "powerproxy.paratroopers"
    local PowerProxy = Actor.Create(proxy, false, { Owner = playerOwner })
    local lz = Utils.Random(withinCposTable)
    PowerProxy.TargetParatroopers(lz.CenterPosition, angle)
end

---@param owner player
---@param proxy string
---@param pos wpos
function Parabomb(owner, pos, angle, proxy)
    angle = angle or Angle.NorthEast
    proxy = proxy or "powerproxy.parabombs"
    local power = Actor.Create(proxy, false, { Owner = owner })
    power.TargetAirstrike(pos, angle)
end

---@param playerOwner player
---@param enter cpos
---@param rally cpos
---@param types table { "e1", "e1", "e1", "e3", "e3" }, etc.
---@param timeinterval number Time in-between each unit appearing
---@param repeatAfter number Integer number of seconds after which to create another group of units
---@return table The spawned units
function SendUnits(playerOwner, enter, rally, types, timeinterval, repeatAfter)
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
---@param types table { "e1", "e1", "e1", "e3", "e3" }, etc. Units within transport
---@param enter cpos
---@param rally cpos
---@param exit cpos
---@param repeatAfter number Integer number of seconds after which to create another transport
---@return table Returns a table in which index 1 is the transport and index 2 is a table containing the units inside the transport.
function SendTransport(playerOwner, transType, types, enter, rally, exit, repeatAfter)
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