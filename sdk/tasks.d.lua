---@meta
---@alias YuriTaskState 'idle'|'waiting'|'observing'|'observed'|'already_satisfied'|'declined'|'timed_out'|'cancelled'|'failed'|'disposed'
---@class YuriTaskStatus
---@field kind 'teleport'|'equip'
---@field state YuriTaskState
---@field message string
---@field request_id? string
---@field accepted boolean Host request acceptance, not proof of the effect.
---@field observed boolean True only after matching fresh snapshots.
---@field samples integer Consecutive matching distinct snapshot samples.
---@field elapsed number Seconds since start; stops advancing after a terminal result.
---@class YuriTaskOptions
---@field timeout? number 1..60 seconds; default 15.
---@field samples? integer 2..5 distinct fresh snapshots; default 2.
---@field radius? number Teleport only: 1..10 metres; default 3.
---@class YuriActionTask
local task={}
---@return boolean started
---@return string? reason
function task:start() end
---@return YuriTaskStatus
function task:status() end
---@param callback fun(result:YuriTaskStatus)
---@return YuriActionTask
function task:on_finish(callback) end
---@return YuriActionTask
function task:cancel() end
function task:dispose() end
---@class YuriTasks
local tasks={}
---@param handle string Loaded entity handle; destination position is captured at start.
---@param options? YuriTaskOptions
---@return YuriActionTask Inert until start; requires game.read, entities.read, actions.teleport.
function tasks.teleport(handle,options) end
---@param handle string Owned Loftia tool-type handle.
---@param options? YuriTaskOptions Radius is not valid for equip.
---@return YuriActionTask Inert until start; requires game.read, tools.read, actions.equip.
function tasks.equip(handle,options) end
