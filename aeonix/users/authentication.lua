-- User Authentication System for Aeonix OS
-- This module handles user authentication, including password management,
-- two-factor authentication, session management, and various authentication methods.

local bcrypt = require("bcrypt")
local oauth2 = require("oauth2")
local saml = require("saml")
local openid = require("openid")
local logging = require("logging")
local jwt = require("jwt")
local redis = require("redis")
local fido2 = require("fido2")
local argon2 = require("argon2") -- More secure than bcrypt for password hashing

-- Configuration
local config = {
    password_policy = {
        min_length = 16, -- Increased minimum length
        require_special_chars = true,
        require_numbers = true,
        require_uppercase = true,
        require_lowercase = true,
        max_age_days = 60, -- Reduced password age
        prevent_common_passwords = true,
        prevent_password_reuse = true
    },
    lockout = {
        max_attempts = 5,
        duration_minutes = 30,
        progressive_delay = true -- Add increasing delays between attempts
    },
    session = {
        timeout_minutes = 30,
        max_concurrent = 3,
        require_2fa_for_sensitive = true,
        jwt_expiration = 3600, -- 1 hour
        refresh_token_expiration = 604800 -- 1 week
    },
    security = {
        enable_webauthn = true,
        enable_rate_limiting = true,
        rate_limit_window = 300, -- 5 minutes
        rate_limit_max_requests = 100,
        require_secure_transport = true
    }
}

-- Initialize Redis for rate limiting and session management
local redis_client = redis.connect({
    host = "127.0.0.1",
    port = 6379,
    database = 0
})

-- User storage with improved structure
local users = {}
local sessions = {}
local failed_attempts = {}
local password_history = {}

-- Helper function to validate password strength
-- @param password: The password to validate
-- @return: Boolean indicating if password meets requirements, error message if not
local function validatePassword(password, username)
    if #password < config.password_policy.min_length then
        return false, "Password must be at least " .. config.password_policy.min_length .. " characters"
    end
    
    if config.password_policy.require_special_chars and not password:match("[%p]") then
        return false, "Password must contain special characters"
    end
    
    if config.password_policy.require_numbers and not password:match("%d") then
        return false, "Password must contain numbers"
    end
    
    if config.password_policy.require_uppercase and not password:match("%u") then
        return false, "Password must contain uppercase letters"
    end
    
    if config.password_policy.require_lowercase and not password:match("%l") then
        return false, "Password must contain lowercase letters"
    end

    -- Check for common passwords
    if config.password_policy.prevent_common_passwords and isCommonPassword(password) then
        return false, "Password is too common"
    end

    -- Check password history
    if config.password_policy.prevent_password_reuse and isPasswordReused(username, password) then
        return false, "Password was used recently"
    end

    -- Check if password contains username
    if string.lower(password):match(string.lower(username)) then
        return false, "Password cannot contain username"
    end
    
    return true
end

-- Function to check if password is commonly used
local function isCommonPassword(password)
    local common_passwords = redis_client:get("common_passwords")
    return common_passwords and common_passwords:find(password)
end

-- Function to check password history
local function isPasswordReused(username, password)
    local history = password_history[username] or {}
    for _, old_hash in ipairs(history) do
        if argon2.verify(old_hash, password) then
            return true
        end
    end
    return false
end

-- Function to update password history
local function updatePasswordHistory(username, password_hash)
    password_history[username] = password_history[username] or {}
    table.insert(password_history[username], 1, password_hash)
    if #password_history[username] > 5 then
        table.remove(password_history[username])
    end
end

-- Helper function to check account lockout
-- @param username: The username to check
-- @return: Boolean indicating if account is locked
local function isAccountLocked(username)
    local attempts = failed_attempts[username]
    if not attempts then return false end
    
    if attempts.count >= config.lockout.max_attempts then
        local lockout_end = attempts.timestamp + (config.lockout.duration_minutes * 60)
        if os.time() < lockout_end then
            return true
        else
            failed_attempts[username] = nil
        end
    end
    return false
end

-- Function to register a new user
-- @param username: Username for the new account
-- @param password: Password for the new account
-- @param options: Additional registration options
-- @return: Boolean indicating success, error message if failed
local function registerUser(username, password, options)
    options = options or {}
    
    if users[username] then
        return false, "Username already exists"
    end
    
    local valid, err = validatePassword(password, username)
    if not valid then
        return false, err
    end
    
    -- Hash the password with Argon2
    local hashedPassword = argon2.hash_encoded(password, argon2.generate_salt())
    
    -- Store password history
    updatePasswordHistory(username, hashedPassword)
    
    users[username] = {
        password = hashedPassword,
        created_at = os.time(),
        password_updated_at = os.time(),
        two_factor_enabled = options.two_factor_enabled or false,
        biometric_enabled = options.biometric_enabled or false,
        webauthn_enabled = options.webauthn_enabled or false,
        webauthn_credentials = {},
        security_questions = options.security_questions or {},
        last_password_change = os.time(),
        account_type = options.account_type or "standard",
        status = "active",
        failed_attempts = 0,
        last_login = nil
    }
    
    -- Set up rate limiting
    if config.security.enable_rate_limiting then
        redis_client:set("rate_limit:" .. username, 0, "EX", config.security.rate_limit_window)
    end
    
    logging.info("User registered: " .. username)
    return true
end

-- Function to authenticate a user
-- @param username: Username to authenticate
-- @param password: Password to verify
-- @param second_factor: Two-factor authentication code (optional)
-- @param webauthn_data: WebAuthn authentication data (optional)
-- @return: Boolean indicating success, error message if failed, session token if successful
local function authenticateUser(username, password, second_factor, webauthn_data)
    -- Check rate limiting
    if config.security.enable_rate_limiting then
        local attempts = tonumber(redis_client:get("rate_limit:" .. username)) or 0
        if attempts >= config.security.rate_limit_max_requests then
            return false, "Too many authentication attempts. Please try again later."
        end
        redis_client:incr("rate_limit:" .. username)
    end

    if isAccountLocked(username) then
        return false, "Account is locked due to too many failed attempts"
    end
    
    local user = users[username]
    if not user then
        return false, "Invalid username or password"
    end

    -- WebAuthn authentication
    if user.webauthn_enabled and webauthn_data then
        local webauthn_result = fido2.verify(webauthn_data, user.webauthn_credentials)
        if not webauthn_result.success then
            return false, "WebAuthn authentication failed"
        end
    else
        -- Password authentication
        if not argon2.verify(user.password, password) then
            -- Track failed attempts with progressive delay
            failed_attempts[username] = failed_attempts[username] or {count = 0}
            failed_attempts[username].count = failed_attempts[username].count + 1
            failed_attempts[username].timestamp = os.time()
            
            if config.lockout.progressive_delay then
                local delay = math.min(30, math.pow(2, failed_attempts[username].count))
                os.execute("sleep " .. delay)
            end
            
            return false, "Invalid username or password"
        end
        
        -- Check if 2FA is required
        if user.two_factor_enabled then
            if not second_factor then
                return false, "Two-factor authentication required"
            end
            if not verifyTwoFactor(username, second_factor) then
                return false, "Invalid two-factor code"
            end
        end
    end
    
    -- Create JWT session token
    local jwt_payload = {
        sub = username,
        iat = os.time(),
        exp = os.time() + config.session.jwt_expiration,
        type = "access"
    }
    
    local refresh_token_payload = {
        sub = username,
        iat = os.time(),
        exp = os.time() + config.session.refresh_token_expiration,
        type = "refresh"
    }
    
    local access_token = jwt.encode(jwt_payload, config.security.jwt_secret)
    local refresh_token = jwt.encode(refresh_token_payload, config.security.jwt_secret)
    
    -- Store session
    sessions[access_token] = {
        username = username,
        created_at = os.time(),
        last_activity = os.time(),
        refresh_token = refresh_token
    }
    
    -- Reset failed attempts and rate limiting
    failed_attempts[username] = nil
    if config.security.enable_rate_limiting then
        redis_client:del("rate_limit:" .. username)
    end
    
    -- Update user data
    user.last_login = os.time()
    user.failed_attempts = 0
    
    logging.info("User authenticated: " .. username)
    return true, nil, {
        access_token = access_token,
        refresh_token = refresh_token,
        expires_in = config.session.jwt_expiration
    }
end

-- Function to verify two-factor authentication
-- @param username: Username to verify
-- @param code: Two-factor authentication code
-- @return: Boolean indicating if code is valid
local function verifyTwoFactor(username, code)
    -- Here you would implement actual 2FA verification logic
    return code == "000000"  -- Placeholder
end

-- Function to generate a session token
-- @return: New session token
local function generateSessionToken()
    -- Here you would implement actual token generation logic
    return os.time() .. "_" .. math.random(1000000)
end

-- Function to verify a session
-- @param token: JWT token to verify
-- @return: Boolean indicating if session is valid, username if valid, error message if failed
local function verifySession(token)
    -- Verify JWT signature and expiration
    local payload, err = jwt.decode(token, config.security.jwt_secret)
    if not payload then
        return false, nil, "Invalid token: " .. (err or "unknown error")
    end
    
    -- Check if token is expired
    if payload.exp and payload.exp < os.time() then
        return false, nil, "Token expired"
    end
    
    -- Get session
    local session = sessions[token]
    if not session then
        return false, nil, "Session not found"
    end
    
    -- Check session timeout
    local timeout = session.last_activity + (config.session.timeout_minutes * 60)
    if os.time() > timeout then
        sessions[token] = nil
        return false, nil, "Session timeout"
    end
    
    -- Update last activity
    session.last_activity = os.time()
    return true, payload.sub, nil
end

-- Function to refresh access token
-- @param refresh_token: Refresh token
-- @return: New access token if valid, error message if failed
local function refreshAccessToken(refresh_token)
    local payload, err = jwt.decode(refresh_token, config.security.jwt_secret)
    if not payload or payload.type ~= "refresh" then
        return nil, "Invalid refresh token"
    end
    
    if payload.exp < os.time() then
        return nil, "Refresh token expired"
    end
    
    -- Create new access token
    local new_access_payload = {
        sub = payload.sub,
        iat = os.time(),
        exp = os.time() + config.session.jwt_expiration,
        type = "access"
    }
    
    return jwt.encode(new_access_payload, config.security.jwt_secret)
end

-- Function to authenticate with OAuth2
-- @param service: Service to authenticate with
-- @param credentials: OAuth2 credentials
-- @return: Boolean indicating success, error message if failed, token if successful
local function authenticateWithOAuth2(service, credentials)
    local token = oauth2.getToken(service, credentials)
    if not token then
        return false, "OAuth2 authentication failed"
    end
    
    logging.info("OAuth2 authentication successful for service: " .. service)
    return true, nil, token
end

-- Function to authenticate with biometrics
-- @param username: Username to authenticate
-- @param biometric_data: Biometric data for verification
-- @return: Boolean indicating success, error message if failed
local function authenticateWithBiometrics(username, biometric_data)
    local user = users[username]
    if not user or not user.biometric_enabled then
        return false, "Biometric authentication not enabled"
    end
    
    -- Here you would implement actual biometric verification logic
    local success = verifyBiometricData(username, biometric_data)
    if not success then
        return false, "Biometric verification failed"
    end
    
    logging.info("Biometric authentication successful for user: " .. username)
    return true
end

return {
    registerUser = registerUser,
    authenticateUser = authenticateUser,
    authenticateWithOAuth2 = authenticateWithOAuth2,
    authenticateWithBiometrics = authenticateWithBiometrics,
    verifySession = verifySession
}
