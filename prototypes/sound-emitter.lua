if settings.startup["debug"].value then
  log('creating sound emitter prototype')
end
local file_prefix = "__RainWorld-se-supercomputer-sound__/sound/rw-randomGods-sc-"
local icon = "__RainWorld-se-supercomputer-sound__/graphics/blank.png"
if settings.startup["debug"].value then
  log('making emitter visible')
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
              filename = file_prefix.."4.ogg",
              volume = 1
            },
        persistent = true,
    },
    selection_box = {{-2.5, -2.5}, {2.5, 2.5}},
    collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
    collision_mask = {},
    flags = {
        "placeable-neutral",
        "placeable-player",
        --"not-deconstructable",
        "not-blueprintable"
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