-- Uses copied native checks. Ready does not guarantee range, target or damage.
local status = yuri.label("Waiting for Aniimo ability data")
local protect = yuri.toggle("Protect below 30% HP", false)
local function capability(state, name)
    for _, value in ipairs(state.capabilities or {}) do
        if value == name then return true end
    end
    return false
end
yuri.every(1, function()
    local state = yuri.game.state()
    if not state.ready or not capability(state, "abilities.read") then
        yuri.features.release("god_mode")
        status:set_text("Connect the matching Aniimo ability host")
        return
    end
    local known, ready = 0, 0
    for _, ability in ipairs(yuri.abilities.list()) do
        if ability.ready ~= nil then
            known = known + 1
            if ability.ready then ready = ready + 1 end
        end
    end
    local player = yuri.player.get()
    status:set_text("Ready checks: " .. ready .. "/" .. known ..
        " | Energy: " .. tostring(player.energy or "Unknown") ..
        " | Ultimate: " .. tostring(player.ultimate_charge or "Unknown"))
    if protect:get() and player.hp and player.max_hp and player.max_hp > 0 and
            player.hp <= player.max_hp * 0.30 then
        yuri.features.set("god_mode", true)
    else
        yuri.features.release("god_mode")
    end
end)
