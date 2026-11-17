-- Feature leases are restored when this script stops or loses connection.
local status = yuri.label("Waiting for game adapter")
local enabled = yuri.toggle("God mode", false)
yuri.every(1, function()
    if not yuri.game.state().ready then
        status:set_text("Game adapter is not connected")
        return
    end
    if enabled:get() then
        yuri.features.set("god_mode", true)
        status:set_text("Requesting existing Yuri God mode")
    else
        yuri.features.release("god_mode")
        status:set_text("Released — your previous setting is restored")
    end
end)
