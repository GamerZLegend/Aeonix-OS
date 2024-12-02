-- Aeonix OS Desktop Environment Configuration

local awesome = require("awesome")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")

-- Load Aeonix OS specific modules
local aeonix = {
    ai = require("aeonix.ai"),
    themes = require("aeonix.themes"),
    widgets = require("aeonix.widgets"),
    utils = require("aeonix.utils")
}

-- Configuration
local config = {
    -- Theme settings
    theme = "default",
    custom_themes_path = "/usr/share/aeonix/themes",
    
    -- Desktop environments
    environments = {
        kde = {
            enabled = true,
            default = true,
            config_path = "/etc/aeonix/kde"
        },
        awesome = {
            enabled = true,
            config_path = "/etc/aeonix/awesome"
        }
    },
    
    -- AI Features
    ai_optimization = {
        enabled = true,
        resource_monitoring = true,
        adaptive_performance = true,
        power_management = true
    },
    
    -- Multi-display support
    display = {
        adaptive_scaling = true,
        hidpi_support = true,
        wayland_support = true,
        x11_support = true
    },
    
    -- Window management
    window_management = {
        tiling = true,
        floating = true,
        gestures = true,
        snap_assist = true
    },
    
    -- System integration
    system = {
        notifications = true,
        quick_settings = true,
        search = true,
        app_launcher = true
    }
}

-- Initialize desktop environment
function init_desktop()
    -- Set theme
    beautiful.init(aeonix.themes.get_theme_path(config.theme))
    
    -- Initialize AI optimization
    if config.ai_optimization.enabled then
        aeonix.ai.init({
            monitor_resources = config.ai_optimization.resource_monitoring,
            optimize_performance = config.ai_optimization.adaptive_performance,
            manage_power = config.ai_optimization.power_management
        })
    end
    
    -- Set up window management
    awesome.set_window_manager_config({
        tiling = config.window_management.tiling,
        floating = config.window_management.floating,
        gestures = config.window_management.gestures,
        snap_assist = config.window_management.snap_assist
    })
    
    -- Initialize system components
    init_system_components()
    
    -- Load widgets
    load_widgets()
end

-- Initialize system components
function init_system_components()
    -- Notifications
    if config.system.notifications then
        naughty.config.defaults.timeout = 5
        naughty.config.defaults.position = "top_right"
    end
    
    -- Quick settings
    if config.system.quick_settings then
        aeonix.widgets.quick_settings.init()
    end
    
    -- Search
    if config.system.search then
        aeonix.widgets.global_search.init()
    end
    
    -- App launcher
    if config.system.app_launcher then
        aeonix.widgets.app_launcher.init()
    end
end

-- Load desktop widgets
function load_widgets()
    -- System monitor
    local system_monitor = aeonix.widgets.system_monitor({
        cpu = true,
        memory = true,
        disk = true,
        network = true
    })
    
    -- Clock
    local clock = aeonix.widgets.clock({
        format = "%Y-%m-%d %H:%M",
        timezone = "local"
    })
    
    -- Add widgets to wibar
    local wibar = awful.wibar({
        position = "top",
        screen = screen.primary
    })
    
    wibar:setup({
        layout = wibox.layout.align.horizontal,
        system_monitor,
        clock
    })
end

-- Error handling
awesome.connect_signal("debug::error", function(err)
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Error in Aeonix Desktop",
        text = tostring(err)
    })
end)

-- Initialize desktop
init_desktop()
