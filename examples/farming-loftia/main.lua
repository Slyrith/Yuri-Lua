-- Uses Loftia's existing own-garden controllers. Normal seeds/water are spent.
-- Equip the seed stack you want to repeat before enabling the cycle.
local status = yuri.label("Waiting for Loftia")
local enabled = yuri.toggle("Plant, water and harvest my beds", false)
local names = {"auto_plant", "auto_water", "auto_harvest", "farm_walk"}

yuri.every(1, function()
    if not yuri.game.state().ready then
        status:set_text("Connect the matching Loftia host")
        return
    end
    local beds = yuri.farming.beds()
    local planted, capacity, dry = 0, 0, 0
    for _, bed in ipairs(beds) do
        if bed.owned then
            planted = planted + bed.planted
            capacity = capacity + bed.capacity
            dry = dry + bed.dry
        end
    end
    status:set_text("Your beds: " .. #beds .. " | Planted: " .. planted .. "/" .. capacity .. " | Dry: " .. dry)
    for _, name in ipairs(names) do
        if enabled:get() and #beds > 0 then
            yuri.features.set(name, true)
        else
            yuri.features.release(name)
        end
    end
end)
