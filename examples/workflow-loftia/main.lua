-- One nearby resource, one request, then observe whether it disappears.
-- Requires SDK helpers 1.2.1 and the matching private game host.
-- Ordinary interaction reach/cost/focus checks still apply.
assert(yuri.workflow, "Update Yuri Launcher for workflow helpers.")
local status = yuri.label("Ready — select one nearby resource")
local target
local job = yuri.workflow.new("Collect one nearby resource")

job:delay(3) -- Time to return to the game and hide its menu.
job:run(function()
    local nearby = yuri.entities.list("resources", 6)
    assert(#nearby > 0, "No supported resource within 6 m.")
    target = nearby[1].handle
end)
job:request(function()
    return yuri.actions.interact(target)
end, 5)
job:wait_until(function()
    for _, row in ipairs(yuri.entities.list("resources", 6)) do
        if row.handle == target then return false end
    end
    return true -- Snapshot no longer lists it nearby; not an inventory receipt.
end, 10)
job:on_finish(function(result)
    status:set_text(result.state .. ": " .. result.message)
end)

yuri.button("Collect one resource", function()
    local state = job:status().state
    if state == "running" or state == "waiting" then return end
    local ok, reason = job:start()
    status:set_text(ok and "Return to the game and hide Yuri within 3 seconds." or reason)
end)
yuri.button("Stop workflow", function() job:cancel() end)
