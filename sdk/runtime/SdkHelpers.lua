-- Trusted SDK layer. No filesystem, network, native calls or game authority.
local native_on, native_time = yuri.on, yuri.time
local legacy, subscribers, change, click = {}, {}, {}, {}
local timers, serial = {}, 0
local known = {tick = true, session = true, control = true, action = true, game = true, entities = true, farming = true, tools = true, abilities = true, resources = true}

local function callback(value, where)
    if type(value) ~= "function" then error(where .. " needs a function, for example function(value) ... end", 3) end
    return value
end
local function check_event(name)
    if not known[name] then error("Unknown event '" .. tostring(name) .. "'. Use tick, session, control, action, game, entities, farming, tools, abilities or resources.", 3) end
end
function yuri.on(name, fn)
    check_event(name)
    legacy[name] = callback(fn, "yuri.on")
end
yuri.events = {}
function yuri.events.subscribe(name, fn)
    check_event(name)
    callback(fn, "yuri.events.subscribe")
    local list = subscribers[name] or {}
    local clean = {}
    for _, item in ipairs(list) do if item.active then clean[#clean + 1] = item end end
    if #clean >= 32 then error("At most 32 active listeners per event.", 2) end
    local item = {fn = fn, active = true}
    clean[#clean + 1] = item
    subscribers[name] = clean
    return function() item.active = false end
end

local function arg(handle, first, second)
    if first == handle then return second end
    return first
end
local function decorate(handle, id, kind, initial_callback)
    local native_get, native_set, native_text = handle.get, handle.set, handle.set_text
    handle.get = function() return native_get() end
    handle.set = function(first, second) native_set(arg(handle, first, second)); return handle end
    handle.set_text = function(first, second) native_text(arg(handle, first, second)); return handle end
    if kind == "button" then
        handle.on_click = function(first, second) click[id] = callback(arg(handle, first, second), "on_click"); return handle end
        if initial_callback ~= nil then handle.on_click(initial_callback) end
    elseif kind == "toggle" or kind == "slider" then
        handle.on_change = function(first, second) change[id] = callback(arg(handle, first, second), "on_change"); return handle end
        if initial_callback ~= nil then handle.on_change(initial_callback) end
    end
    return handle
end
if yuri.ui then
    local label, toggle, slider, button = yuri.ui.label, yuri.ui.toggle, yuri.ui.slider, yuri.ui.button
    function yuri.ui.label(id, text) return decorate(label(id, text), id, "label") end
    function yuri.ui.toggle(id, text, default, fn) return decorate(toggle(id, text, default), id, "toggle", fn) end
    function yuri.ui.slider(id, text, low, high, default, fn) return decorate(slider(id, text, low, high, default), id, "slider", fn) end
    function yuri.ui.button(id, text, fn) return decorate(button(id, text), id, "button", fn) end
end
local function ui()
    if not yuri.ui then error('Add "ui" to script.json permissions to create controls.', 3) end
    return yuri.ui
end
local function auto_id()
    serial = serial + 1
    return "quick_" .. serial
end
function yuri.label(text) return ui().label(auto_id(), text) end
function yuri.button(text, fn) return ui().button(auto_id(), text, fn) end
function yuri.toggle(text, default, fn)
    if type(default) == "function" then fn, default = default, false end
    if default == nil then default = false end
    if type(default) ~= "boolean" then error("A toggle default must be true or false.", 2) end
    return ui().toggle(auto_id(), text, default, fn)
end
function yuri.slider(text, low, high, default, fn) return ui().slider(auto_id(), text, low, high, default, fn) end

if yuri.storage then
    yuri.settings = {}
    function yuri.settings.set(key, value)
        local kind, encoded = type(value), nil
        if kind == "string" then encoded = "s:" .. value
        elseif kind == "boolean" then encoded = value and "b:1" or "b:0"
        elseif kind == "number" and value == value and math.abs(value) < math.huge then encoded = "n:" .. tostring(value)
        else error("Save a string, true/false or a finite number with yuri.settings.set.", 2) end
        yuri.storage.set(key, "@yuri:1:" .. encoded)
    end
    function yuri.settings.get(key, default)
        local saved = yuri.storage.get(key)
        if saved == nil then return default end
        if string.sub(saved, 1, 8) == "@yuri:1:" then
            local kind, value = string.sub(saved, 9, 9), string.sub(saved, 11)
            if kind == "s" then return value end
            if kind == "b" then return value == "1" end
            if kind == "n" then return tonumber(value) or default end
        end
        return saved -- API 1.0 strings stay readable.
    end
end

local function schedule(seconds, fn, repeat_timer)
    if type(seconds) ~= "number" or seconds ~= seconds or seconds < 1 or seconds > 86400 then
        error("Timer seconds must be a number from 1 to 86400. Timers are checked about once per second.", 3)
    end
    callback(fn, "Timer")
    local clean = {}
    for _, timer in ipairs(timers) do if timer.active then clean[#clean + 1] = timer end end
    if #clean >= 16 then error("At most 16 active timers per script.", 3) end
    local timer = {active = true, delay = seconds, due = native_time() + seconds, fn = fn, repeat_timer = repeat_timer}
    clean[#clean + 1] = timer
    timers = clean
    return function() timer.active = false end
end
function yuri.after(seconds, fn) return schedule(seconds, fn, false) end
function yuri.every(seconds, fn) return schedule(seconds, fn, true) end

for name in pairs(known) do
    local event_name = name
    native_on(event_name, function(event)
        if event_name == "control" then
            if change[event.id] then change[event.id](event.value) end
            if click[event.id] then click[event.id]() end
        elseif event_name == "tick" then
            local now, current = native_time(), timers
            for i = 1, #current do
                local timer = current[i]
                if timer.active and now >= timer.due then
                    if timer.repeat_timer then timer.due = now + timer.delay else timer.active = false end
                    timer.fn()
                end
            end
        end
        if legacy[event_name] then legacy[event_name](event) end
        local current = subscribers[event_name] or {}
        for i = 1, #current do if current[i].active then current[i].fn(event) end end
    end)
end
