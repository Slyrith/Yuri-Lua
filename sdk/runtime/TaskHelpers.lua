-- Observed outcomes from approved snapshots; never adds native authority.
yuri.tasks = {}
local tasks = {}
local clock, game_state = yuri.time, yuri.game.state
local player_get = yuri.player and yuri.player.get
local entity_list = yuri.entities and yuri.entities.list
local tool_list = yuri.tools and yuri.tools.list
local teleport = yuri.actions and yuri.actions.teleport
local equip = yuri.actions and yuri.actions.equip
local function number(v, low, high, default)
    if v == nil then return default end
    if type(v) ~= 'number' or v ~= v or v < low or v > high then
        error('Task options are outside the documented range.', 3)
    end
    return v
end
local function position(v)
    if type(v) ~= 'table' then return nil end
    for _, k in ipairs({'x','y','z'}) do
        if type(v[k]) ~= 'number' or v[k] ~= v[k] or math.abs(v[k]) > 10000000 then return nil end
    end
    return {x=v.x,y=v.y,z=v.z}
end
local function distance(a,b)
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
local function active(t) return t.state == 'waiting' or t.state == 'observing' end
local function view(t)
    return {kind=t.kind, state=t.state, message=t.message, request_id=t.request,
        accepted=t.accepted, observed=t.state=='observed', samples=t.matches,
        elapsed=t.started and math.max(0,(t.ended or clock())-t.started) or 0}
end
local function finish(t,state,message)
    t.state,t.message,t.ended=state,message,clock()
    if t.finished then
        t.finishing=true
        local ok=pcall(t.finished,view(t))
        t.finishing=false
        if not ok then t.message=message..' (finish callback failed)' end
    end
end
local function context(t,s)
    if not s.ready or s.revision~=t.revision or s.game~=t.game or s.world~=t.world then
        finish(t,'cancelled','Game or world changed; observation stopped.')
        return false
    end
    return true
end
local function fresh(s)
    return type(s.sample)=='number' and type(s.sample_age)=='number' and s.sample_age<=3
end
local function find(rows,handle)
    for _,row in ipairs(rows) do if row.handle==handle then return row end end
end
local function create(kind,handle,options)
    if type(handle)~='string' or #handle<1 or #handle>48 or handle:find('[%c]') then
        error('Use an opaque handle from the current game snapshot.',3)
    end
    if options==nil then options={} end
    if type(options)~='table' then error('Task options must be a table.',3) end
    for k in pairs(options) do
        if k~='timeout' and k~='samples' and not(k=='radius' and kind=='teleport') then error('Unknown task option: '..tostring(k),3) end
    end
    local timeout=number(options.timeout,1,60,15)
    local samples=number(options.samples,2,5,2)
    if samples%1~=0 then error('Task samples must be an integer from 2 to 5.',3) end
    local radius=kind=='teleport' and number(options.radius,1,10,3) or nil
    local slot
    for i=1,4 do if not tasks[i] then slot=i;break end end
    if not slot then error('At most four action tasks per script. Dispose an unused task.',3) end
    local t={kind=kind,handle=handle,timeout=timeout,required=samples,radius=radius,state='idle',message='Ready',matches=0,accepted=false}
    tasks[slot]=t
    local api={}
    function api:status() return view(t) end
    function api:on_finish(fn)
        if type(fn)~='function' then error('on_finish needs a function.',2) end
        if active(t) or t.finishing or t.state=='disposed' then error('Stop the task before changing its callback.',2) end
        t.finished=fn;return self
    end
    function api:start()
        if active(t) or t.finishing or t.state=='disposed' then error('Stop the task before restarting it.',2) end
        -- A rejected restart must not retain an earlier successful result.
        t.state,t.message,t.started,t.ended,t.matches,t.accepted,t.request='idle','Ready',nil,nil,0,false,nil
        local function reject(reason)
            t.state,t.message='failed',reason
            return false,reason
        end
        local s=game_state()
        if s.revision==nil then return reject('Action tasks need game.read permission.') end
        if not s.ready or not s.world then return reject('Connect a ready game first.') end
        if not fresh(s) then return reject('A fresh snapshot from the updated launcher is required.') end
        if kind=='teleport' and not(player_get and entity_list and teleport) then return reject('Teleport tasks need game.read, entities.read and actions.teleport.') end
        if kind=='equip' and not(tool_list and equip) then return reject('Equip tasks need game.read, tools.read and actions.equip on Loftia.') end
        -- Validate/read before queuing the single guarded action. Missing data
        -- never means arrival, equip completion, inventory gain or success.
        local ok,target,origin=pcall(function()
            if kind=='teleport' then
                local e=find(entity_list(nil,500),handle)
                local destination=e and position(e.position)
                local player=player_get();local from=player and position(player.position)
                assert(destination and from,'Loaded target/player position is unavailable.')
                return destination,from
            end
            local tool=find(tool_list(),handle)
            assert(tool,'The selected owned tool is no longer in this snapshot.')
            return tool
        end)
        if not ok then return reject(tostring(target):sub(1,240)) end
        t.revision,t.game,t.world=s.revision,s.game,s.world
        t.target,t.origin,t.started,t.ended,t.matches,t.accepted,t.request=target,origin,clock(),nil,0,false,nil
        t.last_sample=s.sample;t.deadline=clock()+timeout
        if kind=='teleport' and distance(origin,target)<=radius then
            finish(t,'already_satisfied','Already within the requested radius; no action sent.');return true
        elseif kind=='equip' and target.equipped==true then
            finish(t,'already_satisfied','Tool already equipped; no action sent.');return true
        end
        local sent,id=pcall(kind=='teleport' and teleport or equip,handle)
        if not sent then finish(t,'failed',tostring(id):sub(1,240));return false,t.message end
        if type(id)~='string' or #id>48 or not id:match('^a[%w_]+$') then
            finish(t,'failed','The action API did not return a request ID.');return false,t.message
        end
        t.request,t.state,t.message=id,'waiting','Waiting for request acceptance; effect not confirmed.'
        return true
    end
    function api:cancel()
        if t.finishing then error('Cancel after the finish callback returns.',2) end
        if active(t) then finish(t,'cancelled','Observation stopped; an already sent action cannot be recalled.') end
        return self
    end
    function api:dispose()
        if t.state=='disposed' then return end
        if t.finishing then error('Dispose after the finish callback returns.',2) end
        self:cancel();t.finished=nil;t.target=nil;t.origin=nil;t.state='disposed'
        if tasks[slot]==t then tasks[slot]=nil end
    end
    return api
end
function yuri.tasks.teleport(handle,options) return create('teleport',handle,options) end
function yuri.tasks.equip(handle,options) return create('equip',handle,options) end
local function pump(name,event)
    for i=1,4 do
        local t=tasks[i]
        if t and active(t) then
            local s=game_state()
            if context(t,s) then
                if clock()>=t.deadline then
                    finish(t,'timed_out',t.accepted and 'Request accepted, but the effect was not observed. No retry sent.' or 'Request acceptance was not received. No retry sent.')
                elseif name=='action' and t.request==event.id and not t.accepted then
                    if event.ok==true then
                        t.accepted,t.state,t.message=true,'observing','Request accepted; waiting for fresh observed state.'
                        -- The acceptance snapshot itself is not a later effect observation.
                        t.last_sample=s.sample;t.matches=0
                    else finish(t,'declined',tostring(event.message or 'Action declined.'):sub(1,240)) end
                elseif name=='tick' and t.accepted and fresh(s) and s.sample~=t.last_sample then
                    t.last_sample=s.sample
                    local ok,matched=pcall(function()
                        if t.kind=='teleport' then
                            local p=player_get();p=p and position(p.position)
                            return p and distance(p,t.target)<=t.radius and distance(p,t.origin)>=0.25 or false
                        end
                        local row=find(tool_list(),t.handle)
                        return row and row.equipped==true or false
                    end)
                    if not ok then finish(t,'failed','Observation unavailable: '..tostring(matched):sub(1,200))
                    else
                        t.matches=matched==true and t.matches+1 or 0
                        if t.matches>=t.required then
                            finish(t,'observed',t.kind=='teleport' and 'Player position observed near the captured destination.' or 'Selected tool observed equipped.')
                        end
                    end
                elseif name=='tick' and not fresh(s) then
                    t.matches=0;t.message='Waiting for fresh observed game state.'
                end
            end
        end
    end
end
return pump
