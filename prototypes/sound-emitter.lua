if settings.startup["rwse-debug"].value then
  log('creating sound emitter prototype')
end
local icon = "__RainWorld-se-supercomputer-sound__/graphics/blank.png"
if settings.startup["rwse-debug"].value then
  icon = "__base__/graphics/icons/programmable-speaker.png"
end
data:extend
{
  {
    type = "simple-entity",
    name = "sound-emitter",
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
    collision_mask = {},
    flags = {
        "placeable-neutral",
        "placeable-player",
        "not-deconstructable",
        "not-blueprintable",
        --"not-rotatable",
        --"placeable-off-grid",
        --"not-repairable",
        --"not-on-map",
        --"not-blueprintable",
        --"not-deconstructable",
        --"hidden",
        --"hide-alt-info",
        --"not-flammable",
        --"not-in-kill-statistics",
    },
    picture =
    {
      filename = icon,
      priority = "extra-high",
      width = 64,
      height = 64,
      scale = 0.5,
      shift = {0.0, 0.0}
    }
  },
}