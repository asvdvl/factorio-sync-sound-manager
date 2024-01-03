data:extend({
    {
        type = "double-setting",
        name = "rwse-volume",
        setting_type = "startup",
        default_value = 1,
        order = "aa"
    },
    {
        type = "bool-setting",
        name = "rwse-use_simple_sound_system",
        setting_type = "startup",
        default_value = false,
        order = "ba"
    },
    {
        type = "string-setting",
        name = "rwse-working_proto_prefix",
        setting_type = "startup",
        default_value = "se-space-supercomputer",
        allowed_values = {"se-space-supercomputer", "assembling-machine", "<custom>"},
        order = "ca"
    },
    {
        type = "string-setting",
        name = "rwse-working_proto_prefix_custom",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
        auto_trim = true,
        order = "da"
    },
    {
        type = "string-setting",
        name = "rwse-working_proto_type_custom",
        setting_type = "startup",
        default_value = "assembling-machine",
        allow_blank = true,
        auto_trim = true,
        hidden = true,
        order = "db"
    },
    {
        type = "bool-setting",
        name = "rwse-debug",
        setting_type = "startup",
        default_value = false,
        order = "ea"
    },
    {
        type = "bool-setting",
        name = "rwse-sync-machine-state-with-emitter",
        setting_type = "runtime-global",
        default_value = true,
        order = "fa"
    },
})