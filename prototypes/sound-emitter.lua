if settings.startup["fssm-debug"].value then
    log('creating sound emitter prototype')
end
local icon = "__base__/graphics/icons/programmable-speaker.png"
local enitter_name = settings.startup["fssm-parent_name"].value
data:extend
{
    {
        type = "simple-entity",
        name = enitter_name,

        icon = icon,
        icon_size = 64,
        working_sound = {
            sound = {
                    filename = "__base__/sound/silence-1sec.ogg",
                    volume = 1
                },
            persistent = true,
        },

        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
        collision_mask = {layers={}},

        alert_when_damaged = false,
        create_ghost_on_death = false,
        selectable_in_game = settings.startup["fssm-debug"].value,

        resistances = {

        },

        flags = {
            "not-deconstructable",
            "not-blueprintable",
            "not-rotatable",
            "not-on-map",
            "not-blueprintable",
            "not-deconstructable",
            "hide-alt-info",
            "not-flammable",
            "no-automated-item-removal",
            "no-automated-item-insertion",
            "not-in-kill-statistics"
        },

        picture =
        {
            filename = icon,
            priority = "no-atlas",
            width = 64,
            height = 64,
            scale = 0.5,
            shift = {0.0, 0.0}
        }
    },
}

for key in pairs(data.raw["damage-type"]) do
    table.insert(data.raw["simple-entity"][enitter_name].resistances,
    {
        type=key,
        decrease = 0,
        percent = 200
    })
end