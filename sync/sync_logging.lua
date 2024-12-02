-- Logging System for Synchronization Activities

local function logSyncActivity(message)
    local file = io.open("sync_log.txt", "a")
    file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n")
    file:close()
end

return {
    logSyncActivity = logSyncActivity
}
