local enabled = yuri.ui.toggle("enabled", yuri.tr("enabled", "Enable greeting"), false)
local range = yuri.ui.slider("range", yuri.tr("range", "Example range"), 1, 20, 5)
local status = yuri.ui.label("status", yuri.tr("ready", "Ready — this example does not change gameplay."))
yuri.ui.button("hello", yuri.tr("greet", "Say hello"))

yuri.on("session", function(event)
    status.set_text("Selected game: " .. event.game)
end)

yuri.on("control", function(event)
    if event.id == "hello" and enabled.get() then
        yuri.notify(yuri.tr("hello", "Hello from a community script!"))
        yuri.storage.set("last_greeting", "sent")
    elseif event.id == "range" then
        status.set_text("Example range: " .. tostring(range.get()))
    end
end)
