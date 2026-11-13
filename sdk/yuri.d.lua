---@meta
---@class YuriControl
local control = {}
---@return boolean|number|nil
function control.get() end
---@param text string
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
yuri = {ui=ui,storage=storage,api_version="1.0"}
---@param text string Max 500 characters; notifications are labelled with their script owner.
function yuri.notify(text) end
---@param event "tick"|"control"|"session"
---@param callback fun(event:table)
function yuri.on(event,callback) end
---@param key string
---@param fallback? string
---@return string
function yuri.tr(key,fallback) end
