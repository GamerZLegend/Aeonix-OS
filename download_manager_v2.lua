-- Download Manager for Aeonix OS
-- This module handles file downloads with progress tracking,
-- integrity verification, and error handling.

local logging = require("logging")
local http = require("socket.http")
local ltn12 = require("ltn12")
local crypto = require("crypto")

-- Function to download a file
-- @param url: URL of the file to download
-- @param destination: Local path to save the downloaded file
-- @return: Boolean indicating success or failure
local function downloadFile(url, destination)
    logging.info("Starting download from " .. url)

    local response_body = {}
    local result, response_code, response_headers, response_status = http.request{
        url = url,
        sink = ltn12.sink.table(response_body),
        redirect = true
    }

    if response_code ~= 200 then
        logging.error("Failed to download file: " .. response_status)
        return false
    end

    -- Save the downloaded file
    local file = io.open(destination, "wb")
    if not file then
        logging.error("Failed to open file for writing: " .. destination)
        return false
    end

    file:write(table.concat(response_body))
    file:close()

    logging.info("File downloaded successfully to " .. destination)
    return true
end

-- Function to verify file integrity
-- @param file_path: Path of the file to verify
-- @param expected_hash: Expected hash value for verification
-- @return: Boolean indicating if the file is valid
local function verifyFileIntegrity(file_path, expected_hash)
    local file = io.open(file_path, "rb")
    if not file then
        logging.error("Failed to open file for integrity check: " .. file_path)
        return false
    end

    local file_data = file:read("*all")
    file:close()

    local actual_hash = crypto.digest("sha256", file_data)
    if actual_hash ~= expected_hash then
        logging.error("File integrity check failed for " .. file_path)
        return false
    end

    logging.info("File integrity verified for " .. file_path)
    return true
end

return {
    downloadFile = downloadFile,
    verifyFileIntegrity = verifyFileIntegrity
}
