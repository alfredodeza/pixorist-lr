--[[----------------------------------------------------------------------------

PixoristAPI.lua
Common code to initiate Pixorist API requests

--------------------------------------------------------------------------------

(C) Copyright 2013 Alfredo Deza

------------------------------------------------------------------------------]]

    -- Lightroom SDK
local LrBinding = import 'LrBinding'
local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFunctionContext = import 'LrFunctionContext'
local LrHttp = import 'LrHttp'
local LrMD5 = import 'LrMD5'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'
local LrXml = import 'LrXml'
local LrTasks = import 'LrTasks'

local prefs = import 'LrPrefs'.prefsForPlugin()

local bind = LrView.bind
local share = LrView.share

local logger = import 'LrLogger'( 'PixoristAPI' )
logger:enable( 'logfile' )

--============================================================================--

PixoristAPI = {}

--------------------------------------------------------------------------------

local appearsAlive

--------------------------------------------------------------------------------

local function formatError( nativeErrorCode )
    local error_map = { '400 Bad request',
                        '403 Forbidden',
                        '405 Method not Allowed',
                        '409 Conflict',
                        '411 Length Required',
                        '412 Precondition Failed',
                        '416 Request Range not satisfiable',
                        '501 Not Implemented',
                        '503 Service Unavailable' }
    if error_map[ nativeErrorCode ] then
        error_message = error_map[ nativeErrorCode ]
    else
        error_message = nativeErrorCode
    end
    return LOC("$$$/Pixorist/Error/NetworkFailure=An error ocurred contacting the Pixorist web service. Please check your connection and credentials. [Error: ^1]",
                error_message)
end

--------------------------------------------------------------------------------

local function trim( s )

    return string.gsub( s, "^%s*(.-)%s*$", "%1" )

end

--------------------------------------------------------------------------------


-- Some utilities to run System Commands. Can be Async or Not.

--------------------------------------------------------------------------------


function runcommand(cmd)
        logger:trace("about to run blocking command ", cmd)
        status = LrTasks.execute( cmd )
        logger:trace("Status was: ", status)
        -- this is highly idiotic: lua will multiply the exit status (256) by
        -- the exit status of Python so we need to divide it back here
        if not (status == 0) then
            return status / 256
        end
        return status
end

function runAsyncCommand(cmd)
    LrTasks.startAsyncTask( function()
        logger:trace("about to run async command ", cmd)
        status = LrTasks.execute(cmd)
        logger:trace("Status was: ", status)
    end )
end



--------------------------------------------------------------------------------


-- We can't include a Pixorist API key with the source code for this plug-in, so
-- we require you obtain one on your own and enter it through this dialog.

--------------------------------------------------------------------------------


function PixoristAPI.showCredentialsDialog( propertyTable )

    LrFunctionContext.callWithContext( 'PixoristAPI.showCredentialsDialog', function( context )

        logger:trace('inside context showCredentialsDialog executing')
        local f = LrView.osFactory()

        local properties = LrBinding.makePropertyTable( context )
        logger:trace("username in dialog ", prefs.username)
        logger:trace("apiKey in dialog ", prefs.apiKey)
        properties.apiKey = prefs.apiKey
        properties.username = prefs.username

        local contents = f:column {
            bind_to_object = properties,
            spacing = f:control_spacing(),
            fill = 1,

            f:static_text {
                title = LOC "$$$/Pixorist/CredentialsDialog/Message=In order to publish to Pixorist you need to define your username and your API key.",
                fill_horizontal = 1,
                width_in_chars = 55,
                height_in_lines = 2,
                size = 'small',
            },

            f:row {
                spacing = f:label_spacing(),

                f:static_text {
                    title = LOC "$$$/Pixorist/CredentialsDialog/Username=Username:",
                    alignment = 'right',
                    width = share 'title_width',
                },

                f:edit_field {
                    fill_horizonal = 1,
                    width_in_chars = 35,
                    value = bind 'username',
                },
            },

            f:row {
                spacing = f:label_spacing(),

                f:static_text {
                    title = LOC "$$$/Pixorist/CredentialsDialog/Key=API Key:",
                    alignment = 'right',
                    width = share 'title_width',
                },

                f:edit_field {
                    fill_horizonal = 1,
                    width_in_chars = 35,
                    value = bind 'apiKey',
                },
            },
        }

        local result = LrDialogs.presentModalDialog {
                title = LOC "$$$/Pixorist/ApiKeyDialog/Title=Enter Your Pixorist API credentials",
                contents = contents,
                accessoryView = f:push_button {
                    title = LOC "$$$/Pixorist/ApiKeyDialog/GoToPixorist=Get Pixorist API Keys...",
                    action = function()
                        LrHttp.openUrlInBrowser( "https://www.pixorist.com/settings/" )
                    end
                },
            }

        logger:trace("what is result? ", result)
        if result == 'ok' then

            prefs.username = trim ( properties.username )
            prefs.apiKey = trim ( properties.apiKey )
            propertyTable.username = prefs.username
            propertyTable.apiKey = prefs.apiKey
            logger:trace("saving username and password")
        else

            LrErrors.throwCanceled()

        end

    end )

end

--------------------------------------------------------------------------------
-- 
-- function PixoristAPI.getApiKeyAndSecret()
-- 
--     local apiKey, sharedSecret = prefs.apiKey, prefs.sharedSecret
--     return apiKey, sharedSecret
-- 
-- end
-- 
-- --------------------------------------------------------------------------------
-- 
-- function PixoristAPI.makeApiSignature( params )
-- 
--     -- If no API key, add it in now.
-- 
--     local apiKey, sharedSecret = PixoristAPI.getApiKeyAndSecret()
-- 
--     if not params.api_key then
--         params.api_key = apiKey
--     end
-- 
--     -- Get list of arguments in sorted order.
-- 
--     local argNames = {}
--     for name in pairs( params ) do
--         table.insert( argNames, name )
--     end
-- 
--     table.sort( argNames )
-- 
--     -- Build the secret string to be MD5 hashed.
-- 
--     local allArgs = sharedSecret
--     for _, name in ipairs( argNames ) do
--         if params[ name ] then  -- might be false
--             allArgs = string.format( '%s%s%s', allArgs, name, params[ name ] )
--         end
--     end
-- 
--     -- MD5 hash this string.
-- 
--     return LrMD5.digest( allArgs )
-- 
-- end
-- 
--------------------------------------------------------------------------------

-- function PixoristAPI.callRestMethod( propertyTable, params )
-- 
--     -- Automatically add API key.
-- 
--     local apiKey = PixoristAPI.getApiKeyAndSecret()
-- 
--     if not params.api_key then
--         params.api_key = apiKey
--     end
-- 
--     -- Remove any special values from params.
-- 
--     local suppressError = params.suppressError
--     local suppressErrorCodes = params.suppressErrorCodes
--     local skipAuthToken = params.skipAuthToken
-- 
--     params.suppressError = nil
--     params.suppressErrorCodes = nil
--     params.skipAuthToken = nil
-- 
-- end
-- 
-- 
function PixoristAPI.create( fileName, filePath)

    -- FIXME: this needs to be an HTTP request
    result = runcommand('python ' .. _PLUGIN.path .. '/s3.py create ' .. prefs.apiKey .. ' ' .. prefs.sharedSecret .. ' ' .. prefs.bucket .. ' ' .. fileName .. ' ' .. filePath)
    if not (result == 0) then
		LrErrors.throwUserError( formatError( result ) )
        LrErrors.throwCanceled()
    end

end


--------------------------------------------------------------------------------

function PixoristAPI.uploadPhoto( propertyTable, params )

    logger:info( 'uploading photo ', params.filePath )
    local filePath = params.filePath
    local fileName = LrPathUtils.leafName( filePath )

    PixoristAPI.create( fileName, filePath )

end

--------------------------------------------------------------------------------

function PixoristAPI.constructPhotoURL( propertyTable, params )

    -- TODO: It would be nice to have this at some point
end

--------------------------------------------------------------------------------

function PixoristAPI.deletePhoto( fileName )

    -- TODO: maybe implement this? Not sure this is a good idea
    logger:info( 'deleting photo ', fileName )
    --local filePath = params.filePath
    --local fileName = LrPathUtils.leafName( filePath )

    -- PixoristAPI.delete( fileName )
end

