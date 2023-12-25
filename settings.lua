local settings = {
    {
        type = "double-setting",
        name = "volume",
        setting_type = "startup",
        default_value = 1,
        was_changed_in = 1
    },
    {
        type = "bool-setting",
        name = "use_doppler_shift",
        setting_type = "startup",
        default_value = true,
        was_changed_in = 1
    },
    {
        type = "int-setting",
        name = "default-max_sounds_per_type",
        setting_type = "startup",
        default_value = 1,
        minimum_value = 0,
        maximum_value = 255,
        was_changed_in = 0
    },
    {
        type = "bool-setting",
        name = "use_simple_sound_system",
        setting_type = "startup",
        default_value = false,
        was_changed_in = 0
    },
    {
        type = "bool-setting",
        name = "debug",
        setting_type = "startup",
        default_value = false
    },
    {
        type = "int-setting",
        --hidden = true,
        name = "settings-version",
        setting_type = "startup",
        minimum_value = 0,
        default_value = 0   --kludge for detect old settings, aka "migrations", actualy def value = 1(will change in settings-final-fixes.lua)
    },
}
if not _G.settings then
    data:extend(settings)
end
return settings