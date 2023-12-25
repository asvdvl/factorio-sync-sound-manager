local current_settings_version = 1
local startup = settings.startup
local prev_version = startup["settings-version"].value
startup["settings-version"].value = current_settings_version

--hey wube, many thanks, because I can't get the default values in a simple way
local defsettings = require('__RainWorld-se-supercomputer-sound__/settings')
if settings.startup["debug"].value then
  log('start settings migration')
end

for _, table in ipairs(defsettings) do
    if settings.startup["debug"].value then
      log('check '..table.name)
    end
    --if was_changed_in defined it means that it need to reset if i think so
    if table.was_changed_in and table.was_changed_in > prev_version and startup[table.name].value ~= table.default_value then
        log('reset settings for '..table.name..' '..tostring(startup[table.name].value)..' > '..tostring(table.default_value))
        startup[table.name].value = table.default_value
    end
end

if settings.startup["debug"].value then
  log('end settings migration')
end