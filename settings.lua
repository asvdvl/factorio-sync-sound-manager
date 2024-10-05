data:extend({
    {
        type = "string-setting",
        name = "fssm-parent_name",
        setting_type = "startup",
        hidden = true,
        default_value = "sound-emitter",
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
    {
        type = "int-setting",
        name = "fssm-limit-of-checks",
        setting_type = "runtime-global",
        default_value = 5000,
        order = "faa"
    },
    {
        type = "int-setting",
        name = "fssm-limit-of-actions",
        setting_type = "runtime-global",
        default_value = 500,
        order = "fab"
    },
    {
        type = "bool-setting",
        name = "fssm-enable-runtime-protect",
        setting_type = "startup",
        default_value = false,
        order = "fb"
    },
})