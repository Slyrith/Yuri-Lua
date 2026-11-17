-- Choose Aniimo or Loftia. Requires the updated private launcher/worker.
-- The creator form fills the permissions. Nothing travels at script load.
assert(yuri.tasks, 'Update Yuri Launcher for action-task helpers 1.2.2.')
local status = yuri.label('Ready — stand near a loaded resource.')
local task, cancel_delay

local function stop()
    if cancel_delay then cancel_delay(); cancel_delay = nil end
    if task then task:dispose(); task = nil end
end

yuri.button('Travel to nearest resource', function()
    stop()
    status:set_text('Switch back to the game and hide Yuri. Starting in 3 seconds…')
    cancel_delay = yuri.after(3, function()
        cancel_delay = nil
        local ok, message = pcall(function()
            local targets = yuri.entities.list('resources', 100)
            assert(#targets > 0, 'No loaded resource nearby. Move closer first.')
            task = yuri.tasks.teleport(targets[1].handle, {timeout=15, radius=3})
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
