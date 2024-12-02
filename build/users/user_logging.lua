-- Logging System for User Activities

local function logUserActivity(username, activity)
    local file = io.open("user_activity_log.txt", "a")
    file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. username .. ": " .. activity .. "\n")
    file:close()
end

return {
    logUserActivity = logUserActivity
}
