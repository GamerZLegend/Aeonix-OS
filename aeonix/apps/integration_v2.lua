-- Aeonix OS Integration Script
-- This script handles the integration of applications with the Aeonix OS system,
-- including installation, uninstallation, and updates.

local logging = require("logging")
local package_manager = require("package_manager_v2") -- Updated to use new package manager

-- Function to install an application
-- @param app_name: Name of the application to install
-- @return: Boolean indicating success or failure
local function installApplication(app_name)
    logging.info("Starting installation of " .. app_name)
    
    local success, err = package_manager.install(app_name)
    if not success then
        logging.error("Failed to install " .. app_name .. ": " .. err)
        return false
    end
    
    logging.info(app_name .. " installed successfully.")
    return true
end

-- Function to uninstall an application
-- @param app_name: Name of the application to uninstall
-- @return: Boolean indicating success or failure
local function uninstallApplication(app_name)
    logging.info("Starting uninstallation of " .. app_name)
    
    local success, err = package_manager.uninstall(app_name)
    if not success then
        logging.error("Failed to uninstall " .. app_name .. ": " .. err)
        return false
    end
    
    logging.info(app_name .. " uninstalled successfully.")
    return true
end

-- Function to update an application
-- @param app_name: Name of the application to update
-- @return: Boolean indicating success or failure
local function updateApplication(app_name)
    logging.info("Starting update of " .. app_name)
    
    local success, err = package_manager.update(app_name)
    if not success then
        logging.error("Failed to update " .. app_name .. ": " .. err)
        return false
    end
    
    logging.info(app_name .. " updated successfully.")
    return true
end

-- Function to list installed applications
-- @return: Table of installed applications
local function listInstalledApplications()
    logging.info("Fetching list of installed applications.")
    
    local installed_apps = package_manager.list_installed()
    return installed_apps
end

return {
    installApplication = installApplication,
    uninstallApplication = uninstallApplication,
    updateApplication = updateApplication,
    listInstalledApplications = listInstalledApplications
}
