data:extend({
    {
        type = "double-setting",
        name = "volume",
        setting_type = "startup",
        default_value = 0.7
    },
    {
        type = "int-setting",
        name = "fade_in_ticks",
        setting_type = "startup",
        default_value = 60,
        minimum_value = 0,
        maximum_value = 4294967295
    },
    {
        type = "int-setting",
        name = "fade_out_ticks",
        setting_type = "startup",
        default_value = 60,
        minimum_value = 0,
        maximum_value = 4294967295
    },
    {
        type = "bool-setting",
        name = "use_doppler_shift",
        setting_type = "startup",
        default_value = false
    },
    {
        type = "int-setting",
        name = "default-max_sounds_per_type",
        setting_type = "startup",
        default_value = 1,
        minimum_value = 0,
        maximum_value = 255
    },
    
})