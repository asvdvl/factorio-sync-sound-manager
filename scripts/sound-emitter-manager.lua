local proto_prefix = settings.startup["rwse-working_proto_prefix"].value
if proto_prefix == "<custom>" then
    proto_prefix = settings.startup["rwse-working_proto_prefix_custom"].value
end

local function debugMsg(text)
    if settings.startup["rwse-debug"].value then
        game.print(text)
    else
        game.log(text)
    end
end

local function coordinateFormat(entity)
    return '['..tostring(entity.position.x)..', '..tostring(entity.position.y)..']'
end

local function on_init()
    for _, surface in pairs(game.surfaces) do
        --destroy all emitters
        local emmiters = surface.find_entities_filtered{type = "simple-entity", name = "sound-emitter"}
        if #emmiters > 0 then
            debugMsg('found '..tostring(#emmiters)..' emitters, on surface '..tostring(surface.name))
            for _, entity in pairs(emmiters) do
                debugMsg('destroy '..coordinateFormat(entity))
                entity.destroy()
            end
        end

        --find all machines and create emitter for it
        local workMachines = surface.find_entities_filtered{type = "assembling-machine", name = proto_prefix..'-3'}
        if #workMachines > 0 then
            debugMsg('found '..tostring(#workMachines)..' machines')
            for _, machine in pairs(workMachines) do
                debugMsg('create emmiter for '..coordinateFormat(machine))
                surface.create_entity{name = "sound-emitter"..'__'..machine.name, position = machine.position}
            end
        end
    end
end

commands.add_command("rwse-init", nil, on_init)

script.on_init(on_init)