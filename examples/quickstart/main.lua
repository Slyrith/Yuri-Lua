-- Your first script. Change the words, then Reload in Yuri.
local message = yuri.label("Ready! Click the button below.")

yuri.button("Say hello", function()
    message:set_text("You made your first Yuri script!")
    yuri.notify("Hello from my script!")
end)

-- This example does not change gameplay.
