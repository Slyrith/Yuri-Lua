---@meta
---@class YuriControl
local control = {}
---@return boolean|number|nil
---@overload fun(self:YuriControl):boolean|number|nil
function control.get() end
---@param text string
---@return YuriControl
---@overload fun(self:YuriControl,text:string):YuriControl
function control.set_text(text) end

---@class YuriUI
local ui = {}
---@param id string Unique lowercase ID, max 48 characters.
---@param label string Max 240 characters.
---@return YuriControl
function ui.label(id,label) end
---@param id string
---@param label string
---@param default boolean
---@return YuriControl
function ui.toggle(id,label,default) end
---@param id string
---@param label string
---@param minimum number
---@param maximum number
---@param default number
---@return YuriControl
function ui.slider(id,label,minimum,maximum,default) end
---@param id string
---@param label string
---@return YuriControl
function ui.button(id,label) end

---@class YuriStorage
local storage = {}
---@param key string
---@return string|nil
function storage.get(key) end
---@param key string
---@param value string Max 1024 characters; 64 keys per script.
function storage.set(key,value) end

---@class YuriAPI
yuri = {ui=ui,storage=storage,api_version="1.1"}
---@param text string Max 500 characters; notifications are labelled with their script owner.
function yuri.notify(text) end
---@param event "tick"|"control"|"session"
---@param callback fun(event:table)
function yuri.on(event,callback) end
---@param key string
---@param fallback? string
---@return string
function yuri.tr(key,fallback) end

--- API 1.1 helpers (Launcher 0.11.0+)
---@param value boolean|number
---@return YuriControl
---@overload fun(self:YuriControl,value:boolean|number):YuriControl
function control.set(value) end
---@param callback fun(value:boolean|number)
---@return YuriControl
---@overload fun(self:YuriControl,callback:fun(value:boolean|number)):YuriControl
function control.on_change(callback) end
---@param callback fun()
---@return YuriControl
---@overload fun(self:YuriControl,callback:fun()):YuriControl
function control.on_click(callback) end
---@param text string
---@return YuriControl
function yuri.label(text) end
---@param text string
---@param callback? fun()
---@return YuriControl
function yuri.button(text,callback) end
---@param text string
---@param default? boolean
---@param callback? fun(value:boolean)
---@return YuriControl
function yuri.toggle(text,default,callback) end
---@param text string
---@param minimum number
---@param maximum number
---@param default number
---@param callback? fun(value:number)
---@return YuriControl
function yuri.slider(text,minimum,maximum,default,callback) end
---@param seconds number 1 to 86400; checked on host ticks.
---@param callback fun()
---@return fun() cancel
function yuri.every(seconds,callback) end
---@param seconds number 1 to 86400; checked on host ticks.
---@param callback fun()
---@return fun() cancel
function yuri.after(seconds,callback) end
---@return number elapsed_seconds
function yuri.time() end
---@param text string Max 500 characters; local owner-labelled log.
function yuri.log(text) end
---@class YuriSettings
yuri.settings={}
---@param key string
---@param default? string|number|boolean
---@return string|number|boolean|nil
function yuri.settings.get(key,default) end
---@param key string
---@param value string|number|boolean
function yuri.settings.set(key,value) end
yuri.events={}
---@param event "tick"|"control"|"session"
---@param callback fun(event:table)
---@return fun() unsubscribe
function yuri.events.subscribe(event,callback) end
