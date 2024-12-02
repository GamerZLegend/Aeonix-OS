-- Settings Management System for Desktop Environment

local settings = {
    theme = "default",
    widgets = {
        cpu_monitor = true,
        memory_monitor = true,
    }
}

local function updateSetting(key, value)
    settings[key] = value
end

local function getSetting(key)
    return settings[key]
end

return {
    updateSetting = updateSetting,
    getSetting = getSetting
}
