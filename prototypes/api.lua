local api = {}

--[[
    look at the README.md file for an explanation of how to use the mod
]]

local function get_setting(name)
    return settings.startup["fssm-"..name].value
end

local clog = function ()end
if get_setting("debug") then
    clog = log
end

clog('required post process api')

function api.applyNewSound(proto, sound_path, volume)
    assert(type(proto) == "table", "proto should be a prototype table")
    assert(type(sound_path) == "string", "sound_path should be a string")
    assert(type(volume) == "nil" or type(volume) == "number", "volume should be nil or number")

    clog('applyNewSound for '..proto.name.." sound path: "..sound_path)

    proto.working_sound = {
        sound = {
            filename = sound_path,
            volume = volume or (proto and proto.working_sound and proto.working_sound.sound and proto.working_sound.sound.volume) or 1
        },
        fade_in_ticks = 30,
        fade_out_ticks = 30,
        max_sounds_per_type = 1
    }
    --TODO add an option when everything is synchronized but always played
    if not get_setting("use_simple_sound_system") then
        --I don't think this is the best way to pass a value to the next function, but factorio ignores all the extra stuff, so why not?
        proto.working_sound.speacker_audible_distance_modifier = proto.working_sound.audible_distance_modifier
        proto.working_sound.audible_distance_modifier = 0
        return api.registerPrototype(proto)
    end
end

function api.registerPrototype(proto)
    assert(type(proto) == "table" and proto.working_sound, "proto should be a prototype table with working_sound")
    clog('clone emitter for '..proto.name)

    local parent = data.raw["simple-entity"][get_setting("parent_name")]
    local soundEmitterCopy = table.deepcopy(parent)
    soundEmitterCopy.name = soundEmitterCopy.name..'__'..proto.name

    if data.raw["simple-entity"][soundEmitterCopy.name] then
        log("[warn] an emitter for "..proto.name.." already exists, but an attempt has been made to create another one. The current changes will be applied")
    end

    soundEmitterCopy.working_sound = table.deepcopy(proto.working_sound)
    soundEmitterCopy.working_sound.audible_distance_modifier = proto.working_sound.speacker_audible_distance_modifier or parent.working_sound.audible_distance_modifier
    soundEmitterCopy.working_sound.persistent = true    --in case if origin not modified this param
    soundEmitterCopy.selection_box = proto.selection_box or parent.selection_box
    soundEmitterCopy.collision_box = proto.collision_box or parent.collision_box

    data:extend{soundEmitterCopy}
    return soundEmitterCopy
end

return api