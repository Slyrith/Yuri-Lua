---@meta
---@class YuriPosition
---@field x number
---@field y number
---@field z number
local position = {}
---@class YuriEntity
---@field handle string Opaque, world-scoped handle. Not a native ID or pointer.
---@field kind string
---@field name string
---@field position YuriPosition
---@field distance number Metres.
---@field hp? number
---@field max_hp? number
local entity = {}
---@class YuriGame
local game = {}
---@class YuriGameState
---@field ready boolean
---@field capabilities string[]
---@field game? string Permissioned game name.
---@field world? string Requires game.read.
---@field revision? number Requires game.read; worker-local context revision.
---@field sample? number Requires game.read and matching launcher. Distinct validated snapshot counter, not render frames.
---@field sample_age? number Seconds since that snapshot counter advanced; missing for absent/regressing stamps.
---@return YuriGameState No internal token, instance identity, raw expiry stamp or data arrays.
function game.state() end
---@class YuriPlayer
local player = {}
---@class YuriPlayerState
---@field position YuriPosition
---@field control? string
---@field hp? number
---@field max_hp? number
---@field energy? number Aniimo only, when the native getter is available.
---@field ultimate_charge? number Aniimo only, when the native getter is available.
local playerState = {}
---@return YuriPlayerState Requires game.read.
function player.get() end
---@class YuriAbility
---@field id integer Observed owned ability configuration ID, not an actor or process pointer.
---@field type integer Native ability type; no Q/E/R binding is assumed.
---@field energy_cost? number
---@field ultimate_cost? number
---@field state_allowed? boolean
---@field cooldown_ready? boolean
---@field cost_available? boolean
---@field ready? boolean Present only when all three gates are known. Not proof of range/target/server acceptance.
local ability = {}
---@class YuriAbilities
local abilities = {}
---@return YuriAbility[] Requires abilities.read; Aniimo only; max 32.
function abilities.list() end
---@class YuriResource
---@field handle string Opaque loaded target handle.
---@field kind 'resources'|'loot'
---@field distance number Metres.
---@field available boolean Current existing host availability predicate.
---@field tag? string Configuration tag, if readable.
---@field quantity? integer Verified loose-pickup field only; absent for nodes and unknown counts.
---@field tool_tags string[] Max four native required tool tags.
local resource = {}
---@class YuriResources
local resources = {}
---@return YuriResource[] Requires resources.read; Loftia only; max 32 within response budget.
function resources.list() end
---@class YuriEntities
local entities = {}
---@param kind? string nil selects all supported loaded kinds.
---@param metres? number Maximum 500.
---@return YuriEntity[] Sorted by distance, maximum 128.
function entities.list(kind, metres) end
---@class YuriActions
local actions = {}
---@param handle string
---@return string requestId Observe yuri.on('action', ...) for acceptance/decline.
function actions.interact(handle) end
---@param handle string
---@return string requestId Acceptance is not proof of arrival.
function actions.teleport(handle) end
---@param handle string Opaque currently owned seed/tool type handle; Loftia only.
---@return string requestId Acceptance is not proof of equip completion. Requires actions.equip.
function actions.equip(handle) end
---@class YuriFeatures
local features = {}
---@return string[] Current host's supported boolean feature names; requires features.
function features.available() end
---@param name 'god_mode'|'no_cooldown'|'multi_hit'|'infinite_stamina'|'auto_loot'|'auto_plant'|'auto_water'|'auto_harvest'|'farm_walk'|'auto_collect'|'auto_perfect_chests'
---@param enabled boolean
function features.set(name, enabled) end
---@param name string
function features.release(name) end
---@class YuriGardenBed
---@field handle string Opaque world-scoped target handle.
---@field owned boolean Only local player's beds are returned.
---@field capacity integer Maximum planting slots.
---@field planted integer Occupied slots.
---@field dry integer Planted slots needing water.
---@field harvestable boolean Normal host harvest-readiness check.
local gardenBed = {}
---@class YuriFarming
local farming = {}
---@return YuriGardenBed[] Loftia only; requires farming.read, max 32 visible owned beds.
function farming.beds() end
---@class YuriOwnedTool
---@field handle string Opaque world/inventory-scoped handle; not a native item ID.
---@field kind 'seeds'|'watering_can'|'hammer'|'pruner'|'locator'
---@field tag string Configuration tag. Not a quantity or individual stack.
---@field equipped boolean
local ownedTool = {}
---@class YuriTools
local tools = {}
---@param kind? 'seeds'|'watering_can'|'hammer'|'pruner'|'locator'
---@return YuriOwnedTool[] Max 32 unique types; requires tools.read.
function tools.list(kind) end
---@return YuriOwnedTool|nil
function tools.equipped() end
---@return string|nil Seed remembered by the existing farming controller; requires tools.read.
function tools.farming_seed() end
---@class YuriRender
local render = {}
---@param id string
---@param handle string
---@param text string Maximum 120 characters.
---@param color? string Hex #RRGGBB.
function render.marker(id, handle, text, color) end
---@param id string
function render.remove(id) end
function render.clear() end
