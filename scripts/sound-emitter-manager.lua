local startup = settings.startup
local proto_type = startup["rwse-working_proto_type_custom"].value
local proto_prefix = startup["rwse-working_proto_prefix"].value
if proto_prefix == "<custom>" then
    proto_prefix = startup["rwse-working_proto_prefix_custom"].value
end

local parentName = 'sound-emitter'

local function debugMsg(text)
    if startup["rwse-debug"].value then
        game.print(text)
        log(text)
    else
        --I hope this is only temporary here, because in my opinion, clogging up the logs just isn’t a good idea.
        log(text)
    end
end

local function coordinateFormat(entity)
    return '['..tostring(entity.position.x)..', '..tostring(entity.position.y)..']'
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

local function on_entity_create(event, dontCheck)

    if itsRightEntity(event.created_entity.name, dontCheck) then
        local entity = event.created_entity
        local surface = entity.surface
        debugMsg('detect new entity '..coordinateFormat(entity)..', on surface '..tostring(surface.name))
        surface.create_entity{name = "sound-emitter"..'__'..entity.name, position = entity.position}
    end
end

local function on_entity_delete(event)
    if itsRightEntity(event.entity.name) then
        local entity = event.entity
        local surface = entity.surface
        local emmiters = surface.find_entities_filtered{type = "simple-entity", name = parentName..'__'..entity.name, position = entity.position}
        for _, entity in pairs(emmiters) do
            debugMsg('destroy '..coordinateFormat(entity))
            entity.destroy()
        end
    end
end

local function on_init()
    global.used_prototypes = {}
    local protoPrefix = "^" .. parentName:gsub("-", "%%-")..'__'
    local i = 1
    for protoName, value in pairs(game.entity_prototypes) do
        if string.find(protoName, protoPrefix) then
            --the only reason why I'm looking for emitters is to make sure that I don't desync with the data stage
            global.used_prototypes[i] = string.sub(protoName, #(parentName..'%__'))
            i = i + 1
        end
    end
    i = nil

    for _, surface in pairs(game.surfaces) do
        --destroy all emitters
        for _, protoName in pairs(global.used_prototypes) do
            local emmiters = surface.find_entities_filtered{type = "simple-entity", name = parentName..'__'..protoName}
            if #emmiters > 0 then
                debugMsg('found '..tostring(#emmiters)..' emitters, on surface '..tostring(surface.name))
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

    --I would like to place this code not in init, but thanks to one Czech company...
    local filters = {}
    for _, protoName in pairs(global.used_prototypes) do
        filters[#filters+1] = {filter = "type", type = proto_type}
        filters[#filters+1] = {filter = "name", name = protoName, mode = "and"}
    end
    script.on_event(defines.events.on_built_entity, on_entity_create, filters)
    script.on_event(defines.events.on_robot_built_entity, on_entity_create, filters)

    script.on_event(defines.events.on_entity_died, on_entity_delete, filters)
    script.on_event(defines.events.on_entity_destroyed, on_entity_delete)
    script.on_event(defines.events.on_player_mined_entity, on_entity_delete, filters)
    script.on_event(defines.events.on_robot_mined_entity, on_entity_delete, filters)
end

local function on_load()
    if not global.used_prototypes then
        log('test')
    end
end

local function on_configuration_changed()
    on_init()
end

commands.add_command("rwse-reinit", {"description.command-reinit"}, on_init)

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)