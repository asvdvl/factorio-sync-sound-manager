local api = {}

local function get_setting(name)
    return settings.startup["fssm-"..name].value
end

if get_setting("debug") then
    log('required post process api')
end

function api.applyNewSound(proto, sound_path)
    assert(type(proto) == "table" and proto.working_sound, "proto should be a prototype table")
    assert(type(sound_path) == "string", "sound_path should be a string")

    if get_setting("debug") then
        log('applyNewSound for '..proto.name.." sound path: "..sound_path)
    end

    proto.working_sound = {
        sound = {
            filename = sound_path,
            volume = get_setting("volume")
        },
        fade_in_ticks = 30,
        fade_out_ticks = 30,
        use_doppler_shift = true,
        max_sounds_per_type = 1
    }

    if not get_setting("use_simple_sound_system") then
        proto.working_sound.audible_distance_modifier = 0
        api.registerPrototype(proto)
    end
end

function api.registerPrototype(proto)
    if get_setting("debug") then
        log('clone emitter for '..proto.name)
    end
    local soundEmitterCopy = table.deepcopy(data.raw["simple-entity"]["sound-emitter"])
    soundEmitterCopy.name = soundEmitterCopy.name..'__'..proto.name
    soundEmitterCopy.working_sound.sound.filename = proto.working_sound.sound.filename
    soundEmitterCopy.selection_box = proto.selection_box
    soundEmitterCopy.collision_box = proto.collision_box
    data:extend{soundEmitterCopy}
end

return api