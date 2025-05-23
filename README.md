# factorio-sync-sound-manager - synchronous playback of sounds and music for the entity(static ones)

[ru desctiption](https://github.com/asvdvl/factorio-sync-sound-manager/blob/master/README.ru.md)

## Description
- This is a core, not a full-fledged mod, and does nothing [without add-ons](https://mods.factorio.com/mod/factorio-sync-sound-manager/dependencies?direction=in&sort=idx&filter=required)!
- Synchronizes sound between identical machines; unfortunately, the mod is heavy on performance. Check the `Settings` section to adjust the limitations.

## Settings
All settings start with `fssm-`.

- `synchronize machine state with emitter` (`sync-machine-state-with-emitter`): If enabled, the mod will poll all machines that may have an emitter every tick to check their state (running/stopped) and, depending on the settings, "turn on"/"turn off" the emitter. If you believe this slows down the game, disable this setting. The mod does nothing else besides checking and managing the emitters.
- `limit of state checks` (`limit-of-checks`): Specifies how many machines will be checked per tick. By default, it's set to 5000, chosen to take 8ms per tick (50% of tick time) on my hardware in vanilla.
- `limit of emitter updates` (`limit-of-actions`): Specifies how many entities will be created/destroyed per tick. By default, it's set to 500, calculated similarly to the value above.
- `Use simple sound system` (`use_simple_sound_system`): Do not create ghost entities for synchronized sound playback. In this case, the machines themselves will play the synchronized sound.
- `debug mode` (`debug`): Enables logging of events and actions.
- (hidden) `fssm-parent_name`: internal name of the parent emitter.

## Commands
- `/fssm-reinit`: removes and re-arranges all emitters.

## Terms
- **Emitter**: An entity that plays sound. The mod creates or removes these based on the machine's status.
- **Machine**: An entity under which the emitter is created. It can be anything, such as an assembler, lab, miner, etc.

## API - data stage
check out the source of [my other mod](https://mods.factorio.com/mod/factorio-synced-labs-sound) if you need an example of how to implement it
requiring:
```lua
local fssm = require("__factorio-sync-sound-manager__/prototypes/api")
```
Examples:
```lua
-- changing the sound for a particular entity.
fssm.applyNewSound(data.raw["assembling-machine"]["assembling-machine-1"], "__my-mod__/my-sound.ogg")

-- changing the sound for a particular entity with custom volume.
fssm.applyNewSound(data.raw["assembling-machine"]["assembling-machine-1"], "__my-mod__/my-sound.ogg", 0.7)

-- just the registration of the entity
fssm.registerPrototype(proto)

-- if you want to check that there is a mod at all/is on.
---- data/runtime stage
if settings.startup["fssm-parent_name"] then
    --code
end

---- settings stage
if data.raw and data.raw["string-setting"] and data.raw["string-setting"]["fssm-parent_name"] then
    --code
end
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

## API - runtime stage
In the following releases
Note: at the moment, the mod determines whether the emitter is needed based on the condition of the machine: works/not active, under the Runtime API, I mean the transfer of the "activation" function for configuration as you need.