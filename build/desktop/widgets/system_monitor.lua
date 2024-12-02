-- System Monitoring Widget for AwesomeWM

local wibox = require("wibox")

-- Create a CPU usage widget
local cpu_widget = wibox.widget {
    widget = wibox.widget.progressbar,
    max_value = 100,
    value = 0,
    background_color = "#222222",
    color = "#ffcc00",
}

-- Function to update CPU usage
local function update_cpu_usage()
    -- Logic to get CPU usage and update the widget
    local cpu_usage = 50 -- Placeholder value
    cpu_widget.value = cpu_usage
end

-- Call update function periodically
gears.timer.start_new(2, function()
    update_cpu_usage()
    return true
end)

return cpu_widget
