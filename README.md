# factorio-sync-sound-manager - synchronous playback of sounds and music for the entity(static ones)

[ru desctiption](https://github.com/asvdvl/factorio-sync-sound-manager/blob/master/README.ru.md)

## Settings
All settings actually start with `fssm-`.
- `use simple sound system`(`use_simple_sound_system`): Don't create ghost entities for sync playing sound.
- `debug`: Enable event and activity logging.
- `sync-machine-state-with-emitter`: If enabled, the mod will poll all machines once a second about their status (running/stopped) and, depending on the option, turn on/off the emitter. If you find that this slows down your game, then turn off this setting. The mod does nothing else except check and control.
- (hidden)`fssm-parent_name`: internal name of the parent emitter

## API - data stage
requiring:
```lua
local fssm = require("__factorio-sync-sound-manager__/prototypes/api")
```
examples:
```lua
-- changing the sound for a particular entity.
fssm.applyNewSound(data.raw["assembling-machine"]["assembling-machine-1"], "__my-mod__/my-sound.ogg")

-- changing the sound for a particular entity with custom volume.
fssm.applyNewSound(data.raw["assembling-machine"]["assembling-machine-1"], "__my-mod__/my-sound.ogg", 0.7)

-- just the registration of the entity
fssm.registerPrototype(proto)
```
- `fssm.applyNewSound(proto, sound_path, volume)`:
    - Applies sound to the prototype(replaces with the specified), also calls `registerPrototype(proto)`.
    Useful if you need to completely owerride the sound to yours.
    - Parameters:
        - `proto`: any entity from data.raw.
        - `sound_path`: path to the sound, e.g. `__base__/sound/silence-1sec.ogg`. [docs](https://lua-api.factorio.com/latest/types/FileName.html)
        - `volume`(optional): [0 - 1], the volume of the sound, if not specified: `proto.working_sound.sound.volume` or `1` will be taken. [docs](https://lua-api.factorio.com/latest/types/Sound.html#volume)
    - Returns: result of registerPrototype call
- `fssm.registerPrototype(proto)`: Registers a prototype(entity) in this mod
    - The main method by which my mod understands which entities it will be working with.
    - Important points for modders(especially if you're bypassing the applyNewSound function or don't want to use my functions at all at the datа stage):
        - In order for the runtime part of the mod to find the entnty-emitter correspondence, the following emitter name format must be observed: `soundEmitterName..'__'..proto.name`. 
        - You can use `settings.startup["fssm-parent_name"].value` to get the parent name. `proto` is an entity in `data.raw`.
        - I suggest on the `working_sound.persistent` parameter to set true on your copy of the emitter. but not necessary, however then there is no point in this mod.
        - when calling this function, the parameter working_sound.persistent in the emitter object is set to true
    - Parameters:
        - `proto`: any entity from data.raw.
        - (hidden, in the object properties)`proto.working_sound.speacker_audible_distance_modifier`: sets the `audible_distance_modifier` for the speaker if specified
    - Returns: the emitter object that was added to data.raw