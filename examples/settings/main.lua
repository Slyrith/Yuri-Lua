-- Remember a setting between script sessions.
local volume = yuri.slider("My setting", 1, 10, yuri.settings.get("level", 5))

volume:on_change(function(value)
    yuri.settings.set("level", value)
    print("Saved setting:", value) -- Look under Settings > Logging.
end)

-- Your script.json includes storage permission for this example.
