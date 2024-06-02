data:extend({
    {
        type = "double-setting",
        name = "fssm-volume",
        setting_type = "startup",
        default_value = 1,
        order = "aa"
    },
    {
        type = "bool-setting",
        name = "fssm-use_simple_sound_system",
        setting_type = "startup",
        default_value = false,
        order = "ba"
    },
    {
        type = "bool-setting",
        name = "fssm-debug",
        setting_type = "startup",
        default_value = false,
        order = "ea"
    },
    {
        type = "bool-setting",
        name = "fssm-sync-machine-state-with-emitter",
        setting_type = "runtime-global",
        default_value = true,
        order = "fa"
    },
})