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
local LrStringUtils = import 'LrStringUtils'

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
                        '401 Unauthorized',
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

function BasicAuthHeaders( username, apiKey )
    credentials = username .. ":" .. apiKey
    local base64data = LrStringUtils.encodeBase64(credentials)
    local authorization = 'Basic ' .. base64data

    local headers = {
        { field = 'Authorization', value = authorization},
    }
    return headers

end

--------------------------------------------------------------------------------

function PixoristAPI.create( fileName, filePath)

    local upload_url = "http://upload.pixorist.com/users/" .. prefs.username .. "/upload/"
    local headers = BasicAuthHeaders(prefs.username, prefs.apiKey )
    local result, hdrs = LrHttp.postMultipart(
        upload_url,
        {{filePath=filePath, fileName=fileName, name='file', contentType = 'image/jpeg'}},
        headers,
        10)

    logger:trace("result ", result)
    logger:trace("Headers ", hdrs)
    logger:trace("Headers status --> ", hdrs['status'])
    if hdrs['status'] >= 400 then
        LrErrors.throwUserError( formatError( hdrs['status']) )
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

