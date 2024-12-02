-- Integration Tests for Aeonix OS
-- This module contains comprehensive tests for various system components

local download_manager = require("download_manager_v2") -- Updated to use new download manager
local authentication = require("authentication") -- Updated to use new authentication system
local sync_service = require("sync_service") -- Updated to use new sync service
local logging = require("logging")

-- Test for downloading a file
local function testDownloadFile()
    local url = "https://example.com/testfile.txt"
    local destination = "/tmp/testfile.txt"
    
    local success = download_manager.downloadFile(url, destination)
    assert(success, "Download failed for " .. url)

    -- Verify file integrity (assuming we know the expected hash)
    local expected_hash = "expected_hash_value_here"
    local integrity_check = download_manager.verifyFileIntegrity(destination, expected_hash)
    assert(integrity_check, "File integrity check failed for " .. destination)

    logging.info("testDownloadFile passed.")
end

-- Test for user registration
local function testUserRegistration()
    local username = "testuser"
    local password = "SecurePassword123!"
    
    local success, err = authentication.registerUser(username, password, { two_factor_enabled = false })
    assert(success, "User registration failed: " .. err)

    logging.info("testUserRegistration passed.")
end

-- Test for synchronization
local function testSyncData()
    local service = "example_service"
    local options = { encryption_key = "test_key" }
    
    local success, stats = sync_service.syncDataWithService(service, options)
    assert(success, "Data synchronization failed.")

    logging.info("testSyncData passed. Stats: " .. require("inspect")(stats))
end

-- Run all tests
local function runTests()
    testDownloadFile()
    testUserRegistration()
    testSyncData()
    logging.info("All tests passed successfully.")
end

runTests()
