---@meta
---@alias YuriWorkflowState 'idle'|'running'|'waiting'|'completed'|'declined'|'failed'|'timed_out'|'cancelled'|'disposed'
---@class YuriWorkflowStatus
---@field name string
---@field state YuriWorkflowState
---@field step integer
---@field total integer
---@field message string
---@field last_result? {id:string,ok:boolean,message:string} Request acceptance/decline, not proof of gameplay effect.
---@class YuriWorkflow
local job={}
---@param callback fun()
---@return YuriWorkflow
function job:run(callback) end
---@param predicate fun():boolean
---@param timeout? number 1..60 seconds, default 10.
---@return YuriWorkflow
function job:wait_until(predicate,timeout) end
---@param callback fun():string Must return the request ID from yuri.actions.
---@param timeout? number 1..60 seconds, default 5.
---@return YuriWorkflow
function job:request(callback,timeout) end
---@param seconds number 1..60.
---@return YuriWorkflow
function job:delay(seconds) end
---@param callback fun(status:YuriWorkflowStatus)
---@return YuriWorkflow
function job:on_finish(callback) end
---@return boolean started
---@return string? reason
function job:start() end
---@return YuriWorkflow
function job:cancel() end
---@return YuriWorkflowStatus
function job:status() end
function job:dispose() end
---@class YuriWorkflows
local workflow={}
---@param name string Up to 80 characters; four workflow objects per script.
---@return YuriWorkflow
function workflow.new(name) end
