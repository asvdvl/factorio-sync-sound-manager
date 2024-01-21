local startup = settings.startup
local emitter_type = "simple-entity"
local proto_type = startup["rwse-working_proto_type_custom"].value
local proto_prefix = startup["rwse-working_proto_prefix"].value
local validStatuses = {
    defines.entity_status.working,
    defines.entity_status.normal,
    defines.entity_status.low_power,
    ----these lines below are for future use, not now
    --defines.entity_status.networks_connected,
    --defines.entity_status.charging,
    --defines.entity_status.discharging,
    --defines.entity_status.fully_charged,
    --defines.entity_status.low_input_fluid,
    --defines.entity_status.preparing_rocket_for_launch,
    --defines.entity_status.waiting_to_launch_rocket,
    --defines.entity_status.launching_rocket,
    --defines.entity_status.recharging_after_power_outage,
}
if proto_prefix == "<custom>" then
    proto_prefix = startup["rwse-working_proto_prefix_custom"].value
end

local parentName = 'sound-emitter'

local function debugMsg(text)
    if startup["rwse-debug"].value then
        game.print(text)
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

local function on_entity_create(event, dontCheck)
    local entity = event.created_entity
    local surface = entity.surface
    --just to be sure
    if not entity or not entity.valid then
        debugMsg('on_entity_create entity not valid!')
        return
    end
    --make sure we are not in "update mode", dontCheck is only true when called manually
    if not dontCheck and settings.global["rwse-sync-machine-state-with-emitter"].value then
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
        surface.create_entity{name = "sound-emitter"..'__'..entity.name, position = entity.position}
        switchStateInGlobTable(entity.position, surface.name, true, true)
        --table.insert(global.entities_positions.enabled[entity.surface.name], entity.position)
    end
end

local function on_entity_delete(event)
    --sometimes this event call without entity row(e.g. if it was beam)
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

local function on_init()
    --glob table init
    global.used_prototypes = {}
    global.entities_positions = {}
    global.entities_positions.enabled = {}
    global.entities_positions.disabled = {}
    for surfaceName, _ in pairs(game.surfaces) do
        global.entities_positions.enabled[surfaceName] = {}
        global.entities_positions.disabled[surfaceName] = {}
    end
    local protoPrefix = "^" .. parentName:gsub("-", "%%-")..'__'

    --find right prototypes
    local i = 1
    for protoName, value in pairs(game.entity_prototypes) do
        if string.find(protoName, protoPrefix) then
            --the only reason why I'm looking for emitters is to make sure that I don't desync with the data stage
            global.used_prototypes[i] = string.sub(protoName, #(parentName..'%__'))
            i = i + 1
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
            local workMachines = surface.find_entities_filtered{type = proto_type, name = protoName}
            if #workMachines > 0 then
                debugMsg('found '..tostring(#workMachines)..' machines')
                for _, machine in pairs(workMachines) do
                    local pseudoEvent = {}
                    pseudoEvent['created_entity'] = machine
                    on_entity_create(pseudoEvent, true)
                end
            end
        end
    end

    game.print('Hello, thanks for installing my mod(modname)!\n'..
        'I want to warn you that this is my first mod executed in a runtime environment,\n'..
        'if you experience problems with crashes/slowdowns,\n'..
        'then in this case I left the option of partial (settings - runtime - '..tostring({"mod-setting-name.rwse-sync-machine-state-with-emitter"})..')'..
        'and full (settings - startup - '..tostring({"mod-setting-name.rwse-use_simple_sound_system"})..') disabling code running in the world (the mod will still work)')

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
    if not settings.global["rwse-sync-machine-state-with-emitter"].value then
        return
    end
    validateGlobalTable()
    for surfaceName, surface in pairs(game.surfaces) do
        for _, protoName in pairs(global.used_prototypes) do
            local disabled_entities_positions = global.entities_positions.disabled[surfaceName]
            local emmiters = surface.find_entities_filtered{type = emitter_type, name = parentName..'__'..protoName}
            if #emmiters > 0 then
                for _, emitter in pairs(emmiters) do
                    local machines = surface.find_entities_filtered{type = proto_type, position = emitter.position}
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
                local machines = surface.find_entities_filtered{type = proto_type, position = position}
                if #machines == 1 and itsRightEntity(machines[1].name) then
                    local machine = machines[1]
                    if isStatusIsWorking(machine.status) then
                        debugMsg('restore emitter for machine '..coordinateFormat(machine))
                        local pseudoEvent = {}
                        pseudoEvent['created_entity'] = machine
                        on_entity_create(pseudoEvent, true)
                        disabled_entities_positions[i] = nil
                    end
                end
            end
        end
    end
end

local function on_configuration_changed()
    debugMsg('detect configuration change')
    if not settings.global["rwse-sync-machine-state-with-emitter"].value then
        return
    end
    on_init()   --In general this is not necessary, but I want to make sure that unserviced machines do not appear
end

--[[
    Thank you BIG to you, wube, you don’t give access to global at the on_load stage and during
    the first execution of control.lua (I can understand this), 
    you don’t give access to prototypes (why?!) until the game is fully loaded,
    so I have to send ALL events and check whether this entity is correct or not,
    in Lua!
    
    Instead of simply going through all the prototypes (which, please note, cannot be changed in the runtime stage)
    and generating a list of filters, or after init generating a list of them and saving them to the global table,
    I will be forced to slow down the game. Thanks.
]]
local filters = {{filter = "type", type = proto_type}}
script.on_event(defines.events.on_built_entity, on_entity_create, filters)
script.on_event(defines.events.on_robot_built_entity, on_entity_create, filters)

script.on_event(defines.events.on_entity_died, on_entity_delete, filters)
script.on_event(defines.events.on_entity_destroyed, on_entity_delete)
script.on_event(defines.events.on_player_mined_entity, on_entity_delete, filters)
script.on_event(defines.events.on_robot_mined_entity, on_entity_delete, filters)

commands.add_command("rwse-reinit", {"description.command-reinit"}, on_init)

script.on_init(on_init)
script.on_nth_tick(60, emitters_update)
script.on_configuration_changed(on_configuration_changed)