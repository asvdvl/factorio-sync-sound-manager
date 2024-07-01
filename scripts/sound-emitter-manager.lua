local startup = settings.startup
local emitter_type = "simple-entity"
local validStatuses = {
    defines.entity_status.working,
    defines.entity_status.normal,
    defines.entity_status.low_power
}

local parentName = settings.startup["fssm-parent_name"].value

local function debugMsg(text)
    if startup["fssm-debug"].value then
        if game then
            game.print(text)
        end
        log(text..'\n')
    else
        --I hope this is only temporary here, because in my opinion, clogging up the logs just isn’t a good idea.
        log(text..'\n')
    end
end

local function coordinateFormat(entity)
    return tostring(entity.surface.name)..':['..tostring(entity.position.x)..', '..tostring(entity.position.y)..']'
end

local function itsRightEntity(name, dontCheck)
    local itsRightEntity = false
    if not dontCheck then
        --make shure that expected entity
        for _, protoName in pairs(global.used_prototypes) do
            if name == protoName then
                itsRightEntity = true
            end
        end
    else
        itsRightEntity = true
    end
    return itsRightEntity
end

local function switchStateInGlobTableFind(entities_positions, position)
    for i, position_intable in pairs(entities_positions) do
        if position_intable.x == position.x and position_intable.y == position.y then
            return i
        end
    end
    return nil
end

local function switchStateInGlobTable(position, surface, newstate, isnew)
    local ent_pos = global.entities_positions

    local entities_positions_rev = ent_pos.enabled[surface]
    local entities_positions = ent_pos.disabled[surface]
    if newstate then
        entities_positions = ent_pos.enabled[surface]
        entities_positions_rev = ent_pos.disabled[surface]
    end

    local ind = switchStateInGlobTableFind(entities_positions, position)
    local ind_rev = switchStateInGlobTableFind(entities_positions_rev, position)
    if isnew then
        if ind then
            return
        end
        if ind_rev then
            entities_positions_rev[ind_rev] = nil
        end
        table.insert(entities_positions_rev, position)
        return
    end

    if ind then
        table.insert(entities_positions_rev, position)
        entities_positions[ind] = nil
    end
end

local function on_entity_create_event(event, dontCheck)
    debugMsg("on_entity_create_event")
    local entity = event.created_entity
    local surface = entity.surface
    --just to be sure
    if not entity or not entity.valid then
        debugMsg('on_entity_create_event entity not valid!')
        return
    end
    --make sure we are not in "update mode", dontCheck is only true when called manually
    if not dontCheck and settings.global["fssm-sync-machine-state-with-emitter"].value then
        debugMsg('detect new entity, mark and do nothing now '..coordinateFormat(entity))
        switchStateInGlobTable(entity.position, surface.name, false, true)
        --table.insert(global.entities_positions.disabled[entity.surface.name], entity.position)
        return
    end
    --also check that we don’t have an emitter yet
    local emmiters = surface.find_entities_filtered{type = emitter_type, name = parentName..'__'..entity.name, position = entity.position}
    if #emmiters > 0 then
        return
    end
    if itsRightEntity(entity.name, dontCheck) then
        debugMsg('detect new entity(or update) '..coordinateFormat(entity))
        surface.create_entity{name = parentName..'__'..entity.name, position = entity.position}
        switchStateInGlobTable(entity.position, surface.name, true, true)
        --table.insert(global.entities_positions.enabled[entity.surface.name], entity.position)
    end
end

local function on_entity_delete_event(event)
    --sometimes this event call without entity row(e.g. if it was beam)
    debugMsg("on_entity_delete")
    if not event.entity or not event.entity.valid then
        debugMsg('on_entity_delete entity not valid!')
        return
    end
    if itsRightEntity(event.entity.name) then
        local entity = event.entity
        local surface = entity.surface
        local emmiters = surface.find_entities_filtered{type = emitter_type, name = parentName..'__'..entity.name, position = entity.position}
        for _, entity in pairs(emmiters) do
            debugMsg('destroy '..coordinateFormat(entity))
            entity.destroy()
        end
        switchStateInGlobTable(entity.position, surface.name, false, true)
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

    local on_entity_create = get_trycatch_protect(on_entity_create_event)
    script.on_event(defines.events.on_built_entity, on_entity_create, filters)
    script.on_event(defines.events.on_robot_built_entity, on_entity_create, filters)

    local on_entity_delete = get_trycatch_protect(on_entity_delete_event)
    script.on_event(defines.events.on_entity_died, on_entity_delete, filters)
    script.on_event(defines.events.on_entity_destroyed, on_entity_delete)
    script.on_event(defines.events.on_player_mined_entity, on_entity_delete, filters)
    script.on_event(defines.events.on_robot_mined_entity, on_entity_delete, filters)
end

local function on_init()
    --glob table init
    debugMsg("on_init")
    global.used_prototypes = {}

    global.event_filters = {}

    global.entities_positions = {}
    global.entities_positions.enabled = {}
    global.entities_positions.disabled = {}

    for surfaceName, _ in pairs(game.surfaces) do
        global.entities_positions.enabled[surfaceName] = {}
        global.entities_positions.disabled[surfaceName] = {}
    end
    local protoPrefix = "^" .. parentName:gsub("-", "%%-")..'__'

    --find right prototypes
    for protoName, value in pairs(game.entity_prototypes) do
        if string.find(protoName, protoPrefix) then
            --the only reason why I'm looking for emitters is to make sure that I don't desync with the data stage
            local entity = string.sub(protoName, #(parentName..'%__'))
            table.insert(global.used_prototypes, entity)
            table.insert(global.event_filters, {filter = "name", name = entity})
        end
    end
    for _, surface in pairs(game.surfaces) do
        --destroy all emitters
        for _, protoName in pairs(global.used_prototypes) do
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
        for _, protoName in pairs(global.used_prototypes) do
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
    if not global.used_prototypes or
        not global.entities_positions or
        not global.entities_positions.enabled or
        not global.entities_positions.disabled
    then
        debugMsg('global table not valid')
        on_init()
    end
end

--shoud return true if entity working(working, normal, low_power, etc)
local function isStatusIsWorking(machineStatus)
    for _, status in pairs(validStatuses) do
        if status == machineStatus then
            return true
        end
    end
    return false
end

local function emitters_update(event)
    if not settings.global["fssm-sync-machine-state-with-emitter"].value then
        return
    end
    validateGlobalTable()
    for surfaceName, surface in pairs(game.surfaces) do
        for _, protoName in pairs(global.used_prototypes) do
            local disabled_entities_positions = global.entities_positions.disabled[surfaceName]
            local emmiters = surface.find_entities_filtered{type = emitter_type, name = parentName..'__'..protoName}
            if #emmiters > 0 then
                for _, emitter in pairs(emmiters) do
                    local machines = surface.find_entities_filtered{name = protoName, position = emitter.position}
                    if #machines == 1 and itsRightEntity(machines[1].name) then
                        local machine = machines[1]
                        if not isStatusIsWorking(machine.status) then
                            debugMsg('detect stopped machine '..coordinateFormat(machine))
                            table.insert(disabled_entities_positions, emitter.position)
                            emitter.destroy()
                        end
                    else
                        debugMsg('An emitter was found that was not assigned to the machine (was destroyed?), '..coordinateFormat(emitter))
                        emitter.destroy()
                    end
                end
            end
            --double processing is certainly bad, but copying tables is even worse
            for i, position in pairs(disabled_entities_positions) do
                local machines = surface.find_entities_filtered{name = protoName, position = position}
                if #machines == 1 and itsRightEntity(machines[1].name) then
                    local machine = machines[1]
                    if isStatusIsWorking(machine.status) then
                        debugMsg('restore emitter for machine '..coordinateFormat(machine))
                        local pseudoEvent = {}
                        pseudoEvent['created_entity'] = machine
                        on_entity_create_event(pseudoEvent, true)
                        disabled_entities_positions[i] = nil
                    end
                end
            end
        end
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
script.on_nth_tick(60, get_trycatch_protect(emitters_update))
script.on_configuration_changed(get_trycatch_protect(on_configuration_changed))