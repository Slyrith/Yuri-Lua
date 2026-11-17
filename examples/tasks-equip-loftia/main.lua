-- Nothing is equipped at load. The manifest supplies the permissions.
assert(yuri.tasks, 'Update Yuri Launcher for action-task helpers 1.2.2.')
local status = yuri.label('Ready — owned watering can required.')
local task, cancel_delay
local function stop()
    if cancel_delay then cancel_delay(); cancel_delay = nil end
    if task then task:dispose(); task = nil end
end
yuri.button('Equip watering can', function()
    stop()
    status:set_text('Return to Loftia and hide the menu within 3 seconds.')
    cancel_delay = yuri.after(3, function()
        cancel_delay = nil
        local ok, message = pcall(function()
            local cans = yuri.tools.list('watering_can')
            assert(#cans > 0, 'No currently owned watering can in this snapshot.')
            task = yuri.tasks.equip(cans[1].handle, {timeout=10})
            task:on_finish(function(result)
                status:set_text(result.state .. ': ' .. result.message)
            end)
            local started, why = task:start()
            assert(started, why)
            status:set_text(task:status().message)
        end)
        if not ok then status:set_text(tostring(message):sub(1,200)) end
    end)
end)
yuri.button('Stop', function()
    stop()
    status:set_text('Stopped. A sent action cannot be recalled.')
end)
