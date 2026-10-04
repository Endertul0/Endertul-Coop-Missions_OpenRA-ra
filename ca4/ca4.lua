---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return table Returns a table full of `cpos`s between (`x1`, `y1`) and (`x2`, `y2`)
local function CreateCposTable(x1, y1, x2, y2)
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
local function Paradrop(playerOwner, withinCposTable, angle, proxy)
    angle = angle or Angle.NorthEast
    proxy = proxy or "powerproxy.paratroopers"
    local PowerProxy = Actor.Create(proxy, false, { Owner = playerOwner })
    local lz = Utils.Random(withinCposTable)
    PowerProxy.TargetParatroopers(lz.CenterPosition, angle)
end

---@param owner player
---@param proxy string
---@param pos wpos
local function Parabomb(owner, pos, angle, proxy)
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
local function SendUnits(playerOwner, enter, rally, types, timeinterval, repeatAfter)
    repeatAfter = repeatAfter or -1
    local units = Reinforcements.Reinforce(playerOwner, types, { enter }, timeinterval)
    Utils.Do(units, function(a)
        if (a.HasProperty("AttackMove")) then
            a.AttackMove(rally)
        else
            a.Move(rally)
        end
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
local function SendTransport(playerOwner, transType, types, enter, rally, exit, repeatAfter)
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
local TanyaStr = "tanya"
local Hint = "hint"
local ChinookStr = "tran"
local WaterTranStr = "lst"

local AReinforceTypes = { "e1", "e1", "e1", "e1", "e1", "e1", "e3", "e3", "e3", "e3", "e2", "e2" }

---@type player
local Allies
---@type player
local Allies1
---@type player
local Allies2

---@type player
local USSR
---@type player
local Balatovik

---@type table<player>
local Humans

local function InfiltrateCutscene()
    BVKMech.Infiltrate(BVKMammoth)
    Trigger.OnInfiltrated(BVKMammoth, function(self, infiltrator)
        ---@type actor
        local tnk1 = BVKMammoth
        tnk1.Attack(Map.ActorsInBox(WallBreak.Position, WallBreak.Position), true, true)
    end)
    Trigger.AfterDelay(DateTime.Seconds(1), function()
        BVKg3TNK1Mech.Infiltrate(BVKg3TNK1)
        Trigger.OnInfiltrated(BVKg3TNK1, function(self, infiltrator)
            ---@type actor
            local tnk2 = BVKg3TNK1
            tnk2.Attack(Map.ActorsInBox(WallBreak.Position, WallBreak.Position), true, true)
        end)
        BVKg3TNK2Mech.Infiltrate(BVKg3TNK2)
        Trigger.OnInfiltrated(BVKg3TNK2, function(self, infiltrator)
            ---@type actor
            local tnk3 = BVKg3TNK2
            tnk3.Attack(Map.ActorsInBox(WallBreak.Position, WallBreak.Position), true, true)
        end)
    end)
    SendUnits(Allies, WallBreak.Position, BVKMammoth.Position, AReinforceTypes)
end

WorldLoaded = function()
    -- SETUP PLAYERS & OTHER INITIAL THINGS
    Allies = Player.GetPlayer("Allies")
    Allies1 = Player.GetPlayer("Allies1")
    Allies2 = Player.GetPlayer("Allies2")

    USSR = Player.GetPlayer("USSR")
    Balatovik = Player.GetPlayer("Balatovik")

    Humans = { Allies1, Allies2 }

    Spy1 = nil
    Eng1 = nil
    Spy2 = nil
    Eng2 = nil

    Camera.Position = CamStart.CenterPosition
    InitObjectives(Allies1)

    -- Setup objectives
    Utils.Do(Humans, function(player)
        if player then
            BlowBarrelsObj = AddPrimaryObjective(player, "blow-barrels")
            PowerGridObj = AddSecondaryObjective(player, "power-down")
        end
    end)

    -- USE FUNCTIONS AND TRIGGERS
    Trigger.AfterDelay(DateTime.Seconds(2), function()
        Media.DisplayMessage(UserInterface.Translate("going-in"), UserInterface.Translate("spy"))
        Units1 = SendUnits(Allies1, TEMPSpyIn.Location, TEMPSpyRally.Location, { "spy.strong", "e6" }, 3)
        --Units1 = SendUnits(Allies1, S1Enter.Location, S1Rally.Location, { "spy.strong", "e6" }, 3)
        Units2 = SendUnits(Allies2, S2Enter.Location, S2Rally.Location, { "spy.strong", "e6" }, 3)
        Trigger.AfterDelay(DateTime.Seconds(1), function()
            Spy1 = Units1[1]
            Eng1 = Units1[2]
            Spy2 = Units2[1]
            Eng2 = Units2[2]
            Trigger.OnAnyKilled({ Spy1, Spy2 }, function()
                Utils.Do(Humans, function(player)
                    player.MarkFailedObjective(BlowBarrelsObj)
                end)
            end)
            Trigger.OnAnyKilled({ Eng1, Eng2 }, function()
                Utils.Do(Humans, function(player)
                    player.MarkFailedObjective(PowerGridObj)
                end)
            end)
        end)
    end)
end