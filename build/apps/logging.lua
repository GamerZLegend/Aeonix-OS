-- Aeonix OS Logging Configuration

local logging = require("logging")
local log = logging.file("aeonix.log")

-- Log levels
local levels = {
    DEBUG = "DEBUG",
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR",
    FATAL = "FATAL"
}

-- Function to log messages
local function log_message(level, message)
    if levels[level] then
        log:write(string.format("[%s] %s: %s", os.date("%Y-%m-%d %H:%M:%S"), level, message))
    else
        log:write(string.format("[%s] UNKNOWN: %s", os.date("%Y-%m-%d %H:%M:%S"), message))
    end
end

-- Function to log debug messages
function log.debug(message)
    log_message("DEBUG", message)
end

-- Function to log info messages
function log.info(message)
    log_message("INFO", message)
end

-- Function to log warning messages
function log.warn(message)
    log_message("WARN", message)
end

-- Function to log error messages
function log.error(message)
    log_message("ERROR", message)
end

-- Function to log fatal messages
function log.fatal(message)
    log_message("FATAL", message)
end

-- Function to set log level
function log.set_level(level)
    log:set_level(level)
end

-- Initialize logging
log.info("Aeonix OS logging initialized.")

return log
