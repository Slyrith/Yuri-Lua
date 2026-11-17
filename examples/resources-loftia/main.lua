local status = yuri.label("Waiting for Loftia resource data")
local pending = false
local function ready()
    local state = yuri.game.state()
    if not state.ready then return false end
    local found = {}
    for _, cap in ipairs(state.capabilities or {}) do found[cap] = true end
    return found["resources.read"] and found["tools.read"] and found["render"]
end
local function compatible(tag, required)
    return tag == required or tag:sub(1, #required + 1) == required .. "."
end
yuri.button("Select owned tool for closest node", function()
    if pending or not ready() then return end
    pending = true
    yuri.notify("Return to Loftia and hide its menu. Checking tools in 3 seconds.")
    yuri.after(3, function()
        pending = false
        if not ready() then return end
        local tools = yuri.tools.list()
        for _, resource in ipairs(yuri.resources.list()) do
            if resource.available and #resource.tool_tags > 0 then
                for _, required in ipairs(resource.tool_tags) do
                    for _, tool in ipairs(tools) do
                        if compatible(tool.tag, required) then
                            yuri.actions.equip(tool.handle)
                            return
                        end
                    end
                end
                yuri.notify("No owned compatible tool for the closest node.")
                return
            end
        end
        yuri.notify("No loaded available tool node.")
    end)
end)
yuri.on("action", function(result) yuri.notify(result.message) end)
yuri.every(1, function()
    yuri.render.clear()
    if not ready() then
        status:set_text("Connect the matching Loftia resource host")
        return
    end
    local available, marked = 0, 0
    for _, resource in ipairs(yuri.resources.list()) do
        if resource.available then
            available = available + 1
            if marked < 8 then
                marked = marked + 1
                local name = resource.tag and resource.tag:match("[^.]+$") or resource.kind
                local text = name:sub(1, 80)
                if resource.quantity then text = text .. " x" .. resource.quantity end
                yuri.render.marker("resource" .. marked, resource.handle, text, "#a8e0ce")
            end
        end
    end
    status:set_text("Available loaded resources: " .. available)
end)
