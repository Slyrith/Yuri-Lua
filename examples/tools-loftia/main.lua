-- Selects only seed/tool types the native host currently lists as owned.
-- No stack quantities are assumed, and a request is not proof of equip completion.
local status = yuri.label("Waiting for Loftia tools")
local pending = false
local requests = {}

local function ready()
    local state = yuri.game.state()
    if not state.ready then return false end
    for _, capability in ipairs(state.capabilities or {}) do
        if capability == "tools.read" then return true end
    end
    return false
end

local function select_after_focus(kind)
    if pending or not ready() then return end
    pending = true
    yuri.notify("Return to Loftia and hide its menu. Selecting in 3 seconds.")
    yuri.after(3, function()
        pending = false
        if not ready() then return end
        local rows = yuri.tools.list(kind)
        if #rows == 0 then
            yuri.notify("No owned " .. kind .. " available.")
            return
        end
        local index = 1
        for i, tool in ipairs(rows) do
            if tool.equipped then index = (i % #rows) + 1 end
        end
        local request = yuri.actions.equip(rows[index].handle)
        requests[request] = true
    end)
end

yuri.button("Select next owned seeds", function() select_after_focus("seeds") end)
yuri.button("Select watering can", function() select_after_focus("watering_can") end)
yuri.on("action", function(result)
    if requests[result.id] then
        requests[result.id] = nil
        yuri.notify(result.message)
    end
end)
yuri.every(1, function()
    if not ready() then
        status:set_text("Connect the matching Loftia tools host")
        return
    end
    local held = yuri.tools.equipped()
    status:set_text("Owned seed types: " .. #yuri.tools.list("seeds") ..
        " | Equipped: " .. (held and held.tag or "None"))
end)
