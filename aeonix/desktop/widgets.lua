-- Widget Configuration for AwesomeWM
-- This module provides a collection of desktop widgets with customizable
-- appearance and behavior.

local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local naughty = require("naughty")

-- Default configuration
local config = {
    update_interval = 5,  -- seconds
    theme = {
        background = "#222222",
        foreground = "#ffffff",
        accent = {
            success = "#00ff00",
            warning = "#ffcc00",
            error = "#ff0000",
            info = "#0000ff"
        },
        font = "Sans 10",
        border_width = 1,
        border_color = "#444444",
        padding = 4
    }
}

-- System Monitoring Widgets
local system = {
    -- CPU Usage Widget
    cpu = wibox.widget {
        {
            {
                widget = wibox.widget.textbox,
                text = " CPU ",
                font = config.theme.font
            },
            {
                widget = wibox.widget.progressbar,
                max_value = 100,
                value = 0,
                background_color = config.theme.background,
                color = config.theme.accent.info,
                forced_height = 20,
                paddings = config.theme.padding
            },
            layout = wibox.layout.fixed.horizontal
        },
        widget = wibox.container.background,
        bg = config.theme.background,
        update_interval = config.update_interval,
        update = function(self)
            -- Here you would implement actual CPU usage monitoring
            self.value = math.random(0, 100)  -- Placeholder
        end
    },

    -- Memory Usage Widget
    memory = wibox.widget {
        {
            {
                widget = wibox.widget.textbox,
                text = " RAM ",
                font = config.theme.font
            },
            {
                widget = wibox.widget.progressbar,
                max_value = 100,
                value = 0,
                background_color = config.theme.background,
                color = config.theme.accent.warning,
                forced_height = 20,
                paddings = config.theme.padding
            },
            layout = wibox.layout.fixed.horizontal
        },
        widget = wibox.container.background,
        bg = config.theme.background,
        update_interval = config.update_interval,
        update = function(self)
            -- Here you would implement actual memory usage monitoring
            self.value = math.random(0, 100)  -- Placeholder
        end
    }
}

-- Power Management Widgets
local power = {
    -- Battery Widget with percentage and status
    battery = wibox.widget {
        {
            {
                widget = wibox.widget.textbox,
                text = " BAT ",
                font = config.theme.font
            },
            {
                widget = wibox.widget.progressbar,
                max_value = 100,
                value = 50,
                background_color = config.theme.background,
                color = config.theme.accent.warning,
                forced_height = 20,
                paddings = config.theme.padding
            },
            layout = wibox.layout.fixed.horizontal
        },
        widget = wibox.container.background,
        bg = config.theme.background,
        update_interval = 60,
        update = function(self)
            -- Here you would implement actual battery monitoring
            self.value = math.random(0, 100)  -- Placeholder
        end
    }
}

-- Network Widgets
local network = {
    -- Network Status Widget
    status = wibox.widget {
        {
            widget = wibox.widget.textbox,
            text = "Network: Connected",
            font = config.theme.font
        },
        widget = wibox.container.background,
        bg = config.theme.background,
        fg = config.theme.foreground,
        update_interval = config.update_interval,
        update = function(self)
            -- Here you would implement actual network status monitoring
            self.text = "Network: " .. (math.random() > 0.5 and "Connected" or "Disconnected")
        end
    },

    -- Network Speed Widget
    speed = wibox.widget {
        {
            widget = wibox.widget.textbox,
            text = "↓ 0 KB/s ↑ 0 KB/s",
            font = config.theme.font
        },
        widget = wibox.container.background,
        bg = config.theme.background,
        fg = config.theme.foreground,
        update_interval = 1,
        update = function(self)
            -- Here you would implement actual network speed monitoring
            local down = math.random(0, 1000)
            local up = math.random(0, 500)
            self.text = string.format("↓ %d KB/s ↑ %d KB/s", down, up)
        end
    }
}

-- Time and Calendar Widgets
local datetime = {
    -- Clock Widget
    clock = wibox.widget {
        {
            widget = wibox.widget.textclock,
            format = " %H:%M ",
            font = config.theme.font,
            refresh = 60
        },
        widget = wibox.container.background,
        bg = config.theme.background,
        fg = config.theme.foreground
    },

    -- Calendar Widget
    calendar = wibox.widget {
        {
            widget = wibox.widget.calendar.month,
            font = config.theme.font,
            start_sunday = true,
            week_numbers = true
        },
        widget = wibox.container.background,
        bg = config.theme.background,
        fg = config.theme.foreground
    }
}

-- Weather Widget
local weather = wibox.widget {
    {
        {
            widget = wibox.widget.textbox,
            text = " Weather: Loading... ",
            font = config.theme.font
        },
        layout = wibox.layout.fixed.horizontal
    },
    widget = wibox.container.background,
    bg = config.theme.background,
    fg = config.theme.foreground,
    update_interval = 300,  -- 5 minutes
    update = function(self)
        -- Here you would implement actual weather data fetching
        self.text = " Weather: " .. math.random(15, 25) .. "°C "
    end
}

-- Function to update all widgets
local function update_widgets()
    for _, widget in pairs(system) do
        if widget.update then widget:update() end
    end
    for _, widget in pairs(power) do
        if widget.update then widget:update() end
    end
    for _, widget in pairs(network) do
        if widget.update then widget:update() end
    end
    if weather.update then weather:update() end
end

-- Set up update timer
gears.timer {
    timeout = config.update_interval,
    call_now = true,
    autostart = true,
    callback = update_widgets
}

-- Return all widgets
return {
    system = system,
    power = power,
    network = network,
    datetime = datetime,
    weather = weather,
    config = config
}
