--[[----------------------------------------------------------------------------

PixoristUser.lua
Pixorist user account management

--------------------------------------------------------------------------------

(C) Copyright 2013 Alfredo Deza

------------------------------------------------------------------------------]]

    -- Lightroom SDK
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'
local LrHttp = import 'LrHttp'

local logger = import 'LrLogger'( 'PixoristAPI' )
local prefs = import 'LrPrefs'.prefsForPlugin()
logger:enable( 'logfile' )

require 'PixoristAPI'


--============================================================================--

PixoristUser = {}

--------------------------------------------------------------------------------


local function storedCredentialsAreValid( propertyTable )
    logger:trace('in stored creds are valid check')
    logger:trace('prefs username ', prefs.username)
    logger:trace('prefs apiKey ', prefs.apiKey)
	is_valid = prefs.username and string.len( prefs.username ) > 0
			and prefs.apiKey and string.len( prefs.apiKey ) > 0 
    logger:trace("credentials are valid? --> ", is_valid)
    return is_valid
end



--------------------------------------------------------------------------------


local function noCredentials( propertyTable )
    logger:trace("noCredentials being called")
    propertyTable.credentialsButtonTitle = LOC "$$$/Pixorist/credentialsButton/NoCredentials=Add"
    propertyTable.credentialsButtonEnabled = true
    propertyTable.validCredentials = false
    propertyTable.credentialsNameTitle = LOC "$$$/Pixorist/credentialsButton/NoCredentials=Add"
    if not prefs.username and not prefs.apiKey then
        propertyTable.credentialsStatus = LOC "$$$/Pixorist/credentialsButton/HasCredentials=No credentials stored"
    elseif prefs.apiKey and not prefs.apiKey == nil then
        logger:trace("evaluated apiKey as True")
        propertyTable.credentialsStatus = LOC "$$$/Pixorist/credentialsButton/HasCredentials=Invalid API Key"
    elseif prefs.username and not prefs.username == nil then
        logger:trace("evaluated username as True")
        propertyTable.credentialsStatus = LOC "$$$/Pixorist/credentialsButton/HasCredentials=No valid username"
    --elseif prefs.apiKey and not prefs.username then
    --    propertyTable.credentialsStatus = LOC "$$$/Pixorist/credentialsButton/HasCredentials=No valid username"
    --elseif prefs.username and not prefs.apiKey then
    --    propertyTable.credentialsStatus = LOC "$$$/Pixorist/credentialsButton/HasCredentials=Invalid API Key"
    else
        propertyTable.credentialsStatus = LOC "$$$/Pixorist/credentialsButton/HasCredentials=No credentials stored"
    end
    logger:trace("no creds: username: ", prefs.username)
    logger:trace("no creds: apiKey: ", prefs.apiKey)

end


function PixoristUser.add_credentials( propertyTable )
    if not propertyTable.LR_editingExistingPublishConnection then
        noCredentials( propertyTable )
    end

    require 'PixoristAPI'
    PixoristAPI.showCredentialsDialog( propertyTable )
    propertyTable.validKeys = true
    propertyTable.validUsername = true
    propertyTable.validCredentials = true
end


--------------------------------------------------------------------------------

local function getDisplayUserNameFromProperties( propertyTable )

    local displayUserName = propertyTable.fullname
    if ( not displayUserName or #displayUserName == 0 )
        or displayUserName == propertyTable.username
    then
        displayUserName = propertyTable.username
    else
        displayUserName = LOC( "$$$/Pixorist/AccountStatus/UserNameAndLoginName=^1 (^2)",
                            propertyTable.fullname,
                            propertyTable.username )
    end

    return displayUserName

end

--------------------------------------------------------------------------------

function PixoristUser.verifyCredentials( propertyTable )

    -- Observe changes to prefs and update status message accordingly.

    local function updateStatus()

        LrTasks.startAsyncTask( function()
            logger:trace( "verifyCredentials: updateStatus() is executing." )
            if storedCredentialsAreValid( propertyTable ) then
                logger:trace("credentials are valid it seems!")

                propertyTable.credentialsNameTitle = LOC "$$$/Pixorist/credentialsButton/EditCredentials=Edit credentials"
                propertyTable.credentialsButtonEnabled = true
                propertyTable.validCredentials = true
                propertyTable.validUsername = true
                propertyTable.validKeys = true
                propertyTable.credentialsStatus = string.format('Credentials stored!')
            else
                logger:trace('[WARN] credentials are not valid so clearing it')
                noCredentials( propertyTable )
            end

        end )

    end

    propertyTable:addObserver( 'username', updateStatus )
    propertyTable:addObserver( 'apiKey', updateStatus )
    updateStatus()
end
