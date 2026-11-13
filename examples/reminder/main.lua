-- A reminder while this script is enabled. Timers stop when you disable it.
local enabled = yuri.toggle("Enable reminder", false)

-- Checked about once per second; this does not pause the game or the script.
yuri.every(30, function()
    if enabled:get() then
        yuri.notify("Time for a short break!")
    end
end)
