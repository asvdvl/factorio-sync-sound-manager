local startup = settings.startup
local table = require('__stdlib__/stdlib/utils/table')
local flib_table = require("__flib__.table")

local emitter_type = "simple-entity"
local parentName = settings.startup["fssm-parent_name"].value

local debugMsg
if startup["fssm-debug"].value then
    function debugMsg(text)
        if game then
            game.print(text)
        end
        log(text..'\n')
    end
else
    --I hope this is only temporary here, because in my opinion, clogging up the logs just isn’t a good idea.
    debugMsg = log
end


local function coordinateFormat(entity)
    return tostring(entity.surface.name)..':['..tostring(entity.position.x)..', '..tostring(entity.position.y)..']'
end

-- returns true if the specified entity name in name was found during mod initialization
local function itsRightEntity(name, dontCheck)
    if dontCheck then
        return true
    end

    --make shure that expected entity
    if global.used_prototypes[name] then
        return true
    end
end

local function validateEntity(entity)
    return entity and entity.valid
end

local function on_entity_create_event(event, dontCheck, emitterUpdateMode)
    debugMsg("on_entity_create_event")
    local entity = event.created_entity
    local surface = entity.surface

    --just to be sure
    if not validateEntity(entity) then
        debugMsg('on_entity_create_event entity not valid!')
        return
    end

    if not itsRightEntity(entity.name, dontCheck) or global.machines[entity.unit_number] and not emitterUpdateMode then
        return
    end

    --make sure we are not in "update mode", dontCheck is only true when called manually
    debugMsg('detect new entity '..coordinateFormat(entity))
    local emitter
    if emitterUpdateMode then
        emitter = surface.create_entity{name = parentName..'__'..entity.name, position = entity.position}
    end
    global.machines[entity.unit_number] = {
        machine = entity,
        emitter = emitter
    }
    if itsRightEntity(entity.name, dontCheck) then
        debugMsg('detect new entity(or update) '..coordinateFormat(entity))
    end
end

---comment
---@param event any
---@param emitterUpdateMode boolean means that we should keep machine in table and work with emitter
---@return boolean? dont_touch_machine is true if event.dont_touch_machine, according flib_table.for_n_of i should return true if i want delete machine
local function on_entity_delete_event(event, emitterUpdateMode)
    --sometimes this event call without entity row(e.g. if it was beam)
    debugMsg("on_entity_delete")
    if not event.entity or not event.entity.valid then
        debugMsg('on_entity_delete entity not valid!')
        return
    end
    local entity = event.entity
    if itsRightEntity(event.entity.name) and global.machines[entity.unit_number] then
        local machine = global.machines[entity.unit_number]
        debugMsg('destroy '..coordinateFormat(entity))
        machine.emitter.destroy()
        if emitterUpdateMode then
            global.machines[entity.unit_number].emitter = nil
        else
            if event.dont_touch_machine then
                return true
            end
            global.machines[entity.unit_number] = nil
        end
    end
end

local function get_trycatch_protect(func)
    if not settings.startup["fssm-enable-runtime-protect"].value then
        return func
    end
    return function(event)
        local success, err = pcall(func, event)
        if not success then
            if game and game.print then
                game.print(err)
            end
            log(err)
        end
    end
end

local function setup_events()
    debugMsg("setup_events")
    local filters = global.event_filters
    assert(type(filters) == "table", "event filters not initialized")

    local e = defines.events
    for _, event_name in pairs({e.on_built_entity, e.on_robot_built_entity, e.script_raised_revive, e.script_raised_built}) do
        script.on_event(
            event_name,
            get_trycatch_protect(on_entity_create_event),
            filters
        )
    end

    local delete_list = {e.on_entity_died, e.on_entity_destroyed, e.on_player_mined_entity, e.on_robot_mined_entity, e.script_raised_destroy}
    not_needed_filter = table.array_to_dictionary({e.on_entity_destroyed}, true)
    for _, event_name in pairs(delete_list) do
        script.on_event(
            event_name,
            get_trycatch_protect(on_entity_delete_event),
            (not not_needed_filter[event_name] and filters) or nil
        )
    end
end

local function on_init()
    --glob table init
    debugMsg("on_init")
    global.used_prototypes = {}
    global.event_filters = {}

    ---@alias unti_number number
    ---@type table<unti_number, {machine: table, emitter: table}>
    global.machines = {}

    local protoPrefix = "^" .. parentName:gsub("-", "%%-")..'__'
    --find right prototypes
    for protoName, value in pairs(game.entity_prototypes) do
        if string.find(protoName, protoPrefix) then
            --the only reason why I'm looking for emitters is to make sure that I don't desync with the data stage
            local entity_name = string.sub(protoName, #(parentName..'%__'))
            global.used_prototypes[entity_name] = 1
            table.insert(global.event_filters, {filter = "name", name = entity_name})
        end
    end
    for _, surface in pairs(game.surfaces) do
        --destroy all emitters
        for protoName in pairs(global.used_prototypes) do
            local emmiters = surface.find_entities_filtered{type = emitter_type, name = parentName..'__'..protoName}
            if #emmiters > 0 then
                debugMsg('found '..tostring(#emmiters)..' emitters')
                for _, entity in pairs(emmiters) do
                    debugMsg('destroy '..coordinateFormat(entity))
                    entity.destroy()
                end
            end
        end

        --find all machines and create emitter for it
        for protoName in pairs(global.used_prototypes) do
            local workMachines = surface.find_entities_filtered{name = protoName}
            if #workMachines > 0 then
                debugMsg('found '..tostring(#workMachines)..' machines')
                for _, machine in pairs(workMachines) do
                    local pseudoEvent = {}
                    pseudoEvent['created_entity'] = machine
                    on_entity_create_event(pseudoEvent, true)
                end
            end
        end
    end
    setup_events()

    game.print('Hello, thanks for installing my mod(factorio sync sound manager)!\n'..
        'I want to warn you that this is my first mod executed in a runtime environment,\n'..
        'if you experience problems with crashes/slowdowns,\n'..
        'then in this case I left the option of partial (settings - runtime - '..tostring({"mod-setting-name.fssm-sync-machine-state-with-emitter"})..')'..
        'and full (settings - startup - '..tostring({"mod-setting-name.fssm-use_simple_sound_system"})..
        ') disabling code running in the world (the mod will still work, but without some features)')
end

local function validateGlobalTable()
    --check that table is wrong
    if not global.used_prototypes or not global.machines then
        debugMsg('global table not valid')
        on_init()
    end
end

--shoud return true if entity working(working, normal, low_power, etc)
local validStatuses = {
    defines.entity_status.working,
    defines.entity_status.normal,
    defines.entity_status.low_power
}
validStatuses = table.array_to_dictionary(validStatuses, true)

local function isStatusIsWorking(machineStatus)
    if validStatuses[machineStatus] then
        return true
    end
    return false
end

local function emitters_update(event)
    if not settings.global["fssm-sync-machine-state-with-emitter"].value then
        return
    end
    validateGlobalTable()

    local machines = global.machines

    local limit_checks = 100
    local limit_of_actions = 10

    local next_key, _, reached_end = flib_table.for_n_of(machines, global.update_index, limit_checks,
    function (value, key)
        local machine = value.machine
        local emitter = value.emitter
        local delete_current_item = false

        if isStatusIsWorking(machine.status) then
            if not emitter then
                debugMsg('restore emitter for machine '..coordinateFormat(machine))
                local pseudoEvent = {}
                pseudoEvent['created_entity'] = machine
                on_entity_create_event(pseudoEvent, true, true)
                limit_of_actions = limit_of_actions - 1
            end
        elseif emitter then
            debugMsg('detect stopped machine '..coordinateFormat(machine))
            local pseudoEvent = {}
            pseudoEvent['entity'] = machine
            pseudoEvent['dont_touch_machine'] = true
            delete_current_item = on_entity_delete_event(pseudoEvent, true) or false
            limit_of_actions = limit_of_actions - 1
        end

        return nil, delete_current_item, limit_of_actions <= 0
    end)
    if reached_end then
        global.update_index = nil
    else
        global.update_index = next_key
    end
end

local function on_configuration_changed()
    debugMsg('detect configuration change')
    if not settings.global["fssm-sync-machine-state-with-emitter"].value then
        return
    end
    on_init()   --In general this is not necessary, but I want to make sure that unserviced machines do not appear
end

commands.add_command("fssm-reinit", {"description.command-reinit"}, get_trycatch_protect(on_init))

script.on_init(get_trycatch_protect(on_init))
script.on_load(get_trycatch_protect(function (...)
    debugMsg("on_load")
    if type(global.event_filters) == "table" then
        setup_events()
    else
        log("event filters not initialized")
    end
end))
script.on_event(defines.events.on_tick, get_trycatch_protect(emitters_update))
script.on_configuration_changed(get_trycatch_protect(on_configuration_changed))
