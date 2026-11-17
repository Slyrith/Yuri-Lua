-- Read-only example. Requires the private gameplay adapter to be connected.
local label = yuri.label("Waiting for the game adapter")
yuri.every(1, function()
    if not yuri.game.state().ready then
        label:set_text("Open your game with the matching Yuri host")
        return
    end
    local resources = yuri.entities.list("resources", 30)
    label:set_text("Loaded resources within 30 m: " .. #resources)
    yuri.render.clear()
    for i = 1, math.min(8, #resources) do
        local item = resources[i]
        yuri.render.marker("resource" .. i, item.handle, item.name, "#a8e0ce")
    end
end)
