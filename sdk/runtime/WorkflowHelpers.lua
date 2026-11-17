-- Per-worker automation sequencing. Uses existing permissioned APIs only.
-- Completion of a request means acceptance, never verified game effects.
yuri.sdk_version = "1.2.2"
yuri.workflow = {}
local jobs = {}
local clock, game_state = yuri.time, yuri.game.state
local function seconds(value, default)
    value = value == nil and default or value
    if type(value) ~= "number" or value ~= value or value < 1 or value > 60 then
        error("Use a timeout or delay from 1 to 60 seconds.", 3)
    end
    return value
end
local function fn(value)
    if type(value) ~= "function" then error("Workflow step needs a function.", 3) end
    return value
end
local function view(job)
    local result = job.result
    return {name=job.name, state=job.state, step=job.index, total=#job.steps,
        message=job.message, last_result=result and {id=result.id, ok=result.ok, message=result.message} or nil}
end
local function finish(job, state, message)
    job.state, job.message, job.pending, job.due = state, message, nil, nil
    if job.finished then
        job.finishing = true
        local ok = pcall(job.finished, view(job))
        job.finishing = false
        if not ok then job.message = message .. " (finish callback failed)" end
    end
end
local function active(job) return job.state == "running" or job.state == "waiting" end
local function context(job)
    local state = game_state()
    if not state.ready or state.revision ~= job.revision or state.game ~= job.game or state.world ~= job.world then
        finish(job, "cancelled", "Game or world changed; remaining steps stopped.")
        return false
    end
    return true
end
function yuri.workflow.new(name)
    if type(name) ~= "string" or #name == 0 or #name > 80 or name:find("[%c]") then
        error("Give the workflow a name from 1 to 80 characters.", 2)
    end
    local slot
    for i=1,4 do if not jobs[i] then slot=i; break end end
    if not slot then error("At most four workflows per script. Dispose an unused workflow first.", 2) end
    local job = {name=name, steps={}, state="idle", index=0, message="Ready"}
    jobs[slot] = job
    local api = {}
    local function editable()
        if job.state == "disposed" then error("This workflow was disposed.", 3) end
        if active(job) or job.finishing then error("Stop the workflow before editing or restarting it.", 3) end
    end
    local function add(kind, callback, timeout)
        editable()
        if #job.steps >= 24 then error("At most 24 steps per workflow.", 3) end
        job.steps[#job.steps+1] = {kind=kind, callback=callback, timeout=timeout}
        return api
    end
    function api:run(callback) return add("run", fn(callback)) end
    function api:wait_until(predicate, timeout) return add("condition", fn(predicate), seconds(timeout, 10)) end
    function api:request(callback, timeout) return add("request", fn(callback), seconds(timeout, 5)) end
    function api:delay(delay) return add("delay", nil, seconds(delay, 1)) end
    function api:on_finish(callback) editable(); job.finished=fn(callback); return self end
    function api:status() return view(job) end
    function api:start()
        editable()
        if #job.steps == 0 then error("Add a step before starting the workflow.", 2) end
        local state = game_state()
        if state.revision == nil then error("Workflows need game.read in script.json permissions.", 2) end
        if not state.ready or not state.game or not state.world then return false, "Connect a ready game first." end
        job.revision, job.game, job.world = state.revision, state.game, state.world
        job.index, job.state, job.message = 1, "running", "Started"
        job.pending, job.due, job.result, job.entered = nil, nil, nil, nil
        job.deadline = clock() + 300
        return true
    end
    function api:cancel()
        if active(job) then finish(job, "cancelled", "Cancelled; already sent requests cannot be recalled.") end
        return self
    end
    function api:dispose()
        if job.state == "disposed" then return end
        if job.finishing then error("Dispose after the finish callback returns.", 2) end
        self:cancel(); job.steps={}; job.finished=nil; job.state="disposed"
        if jobs[slot] == job then jobs[slot]=nil end
    end
    return api
end
local function pump(event_name, event)
    for i=1,4 do
        local job = jobs[i]
        if job and active(job) and context(job) then
            local now = clock()
            if now >= job.deadline then finish(job, "timed_out", "Workflow exceeded five minutes.")
            elseif job.due and now >= job.due then
                if job.steps[job.index].kind == "delay" then
                    job.index, job.due, job.entered = job.index+1, nil, nil
                else finish(job, "timed_out", "Step timed out; no automatic retry.") end
            elseif event_name == "action" and job.pending and event.id == job.pending then
                job.result = {id=event.id, ok=event.ok == true, message=tostring(event.message or ""):sub(1,240)}
                if event.ok == true then
                    job.index, job.pending, job.due, job.entered = job.index+1, nil, nil, nil
                    job.state, job.message = "running", "Request accepted; continuing on the next tick."
                else finish(job, "declined", job.result.message) end
            elseif event_name == "tick" and not job.pending then
                local step = job.steps[job.index]
                if not step then finish(job, "completed", "All steps completed.")
                elseif step.kind == "delay" then
                    if not job.due then job.due=now+step.timeout end
                else
                    local ok, value = pcall(step.callback)
                    if not ok then finish(job, "failed", "Step failed: " .. tostring(value):sub(1,240))
                    elseif step.kind == "run" then job.index=job.index+1
                    elseif step.kind == "condition" then
                        if value == true then job.index, job.due = job.index+1, nil
                        elseif not job.due then job.due=now+step.timeout end
                    elseif type(value) ~= "string" or #value > 48 or not value:match("^a[%w_]+$") then
                        finish(job, "failed", "Request step must return the ID from yuri.actions.")
                    else
                        job.pending, job.due, job.state = value, now+step.timeout, "waiting"
                        job.message = "Waiting for request acceptance."
                    end
                end
            end
        end
    end
end
-- The worker calls this private hook before community event handlers.
-- It does not consume public listener slots or expose a new dispatch API.
return pump
