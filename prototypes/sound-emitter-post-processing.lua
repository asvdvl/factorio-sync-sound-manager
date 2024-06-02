for _, mainProto in pairs(protoList) do
    if settings.startup["fssm-debug"].value then
        log('clone emitter for '..mainProto.name)
    end
    local soundEmitterCopy = table.deepcopy(data.raw["simple-entity"]["sound-emitter"])
    soundEmitterCopy.name = soundEmitterCopy.name..'__'..mainProto.name
    soundEmitterCopy.working_sound.sound.filename = mainProto.working_sound.sound.filename
    soundEmitterCopy.selection_box = mainProto.selection_box
    soundEmitterCopy.collision_box = mainProto.collision_box
    data:extend{soundEmitterCopy}
end
