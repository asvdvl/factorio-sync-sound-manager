data:extend({
    {
        type = "double-setting",
        name = "volume",
        setting_type = "startup",
        default_value = 1
    },
    {
        type = "bool-setting",
        name = "use_doppler_shift",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "int-setting",
        name = "default-max_sounds_per_type",
        setting_type = "startup",
        default_value = 1,
        minimum_value = 0,
        maximum_value = 255
    },
    {
        type = "bool-setting",
        name = "use_simple_sound_system",
        setting_type = "startup",
        default_value = false
    },
    {
        type = "bool-setting",
        name = "debug",
        setting_type = "startup",
        default_value = false
    }
})