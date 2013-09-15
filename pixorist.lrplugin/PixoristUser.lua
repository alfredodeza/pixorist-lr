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
--logger:enable( 'logfile' )

require 'PixoristAPI'


--============================================================================--

PixoristUser = {}

--------------------------------------------------------------------------------

local function storedKeysAreValid( propertyTable )
    return prefs.apiKey and string.len( prefs.apiKey ) > 0
            and prefs.sharedSecret
end

local function storedBucketIsValid( propertyTable )
    local valid_prefs =  prefs.bucket and string.len( prefs.bucket ) > 0
    local valid_bucket = propertyTable.validBucket == true or propertyTable.validBucket == nil
    return valid_prefs and valid_bucket
end


--------------------------------------------------------------------------------

local function noKeys( propertyTable )
    logger:trace("noKeys being called")

    --prefs.apiKey = nil
    --prefs.sharedSecret = nil

    propertyTable.accountStatus = LOC "$$$/Pixorist/AccountStatus/NotLoggedIn=No valid keys"
    propertyTable.keysButtonTitle = LOC "$$$/Pixorist/keysButton/NotLoggedIn=Add keys"
    propertyTable.keysButtonEnabled = true
    propertyTable.validKeys = false

end

local function noBucket( propertyTable )
    logger:trace("noBucket being called")
    --prefs.bucket = nil
    propertyTable.bucketButtonTitle = LOC "$$$/Pixorist/BucketButton/NoBucket=Add bucket"
    propertyTable.bucketButtonEnabled = true
    --propertyTable.validBucket = false
    propertyTable.bucketNameTitle = LOC "$$$/Pixorist/BucketButton/NoBucket=Add bucket"
    if not prefs.bucket then
        propertyTable.bucketStatus = LOC "$$$/Pixorist/BucketButton/HasBucket=No valid bucket"
    else
        propertyTable.bucketStatus = LOC "$$$/Pixorist/BucketButton/HasBucket=Invalid bucket"
    end

end

doingBucket = false

function PixoristUser.validate_bucket( propertyTable )

        local do_url =   'http://' .. prefs.bucket .. ".objects.pixorist.com"
        local result, hdrs = LrHttp.get( do_url )
        logger:trace('Validating bucket against url ', do_url)
        logger:trace('Response from bucket validation ', hdrs['status'])
        local is_valid = hdrs['status'] == 200 or hdrs['status'] == 403
        logger:trace('is valid value ' ,  is_valid)
        return  hdrs['status'] == 200 or hdrs['status'] == 403
end

--------------------------------------------------------------------------------

function PixoristUser.add_bucket( propertyTable )
    if not propertyTable.LR_editingExistingPublishConnection then
        noBucket( propertyTable )
    end
    require 'PixoristAPI'
    PixoristAPI.showBucketDialog()

    LrFunctionContext.postAsyncTaskWithContext( 'Pixorist add_bucket',
    function( context )

        doingBucket = true

        propertyTable.bucketStatus = LOC "$$$/Pixorist/BucketStatus/Status=Verifying bucket..."
        propertyTable.BucketButtonEnabled = false

        LrDialogs.attachErrorDialogToFunctionContext( context )

        -- Make sure bucket is valid when done, or is marked as invalid.

        context:addCleanupHandler( function()
            doingBucket = false

            if not storedBucketIsValid( propertyTable ) then
                logger:trace("cleanup handler saw an invalid bucket")
                noBucket( propertyTable )
            end

        end )

        -- Make sure we have an API key.
        PixoristAPI.getApiKeyAndSecret()

        require 'PixoristAPI'
        local is_valid = PixoristUser.validate_bucket()
        logger:trace('receiving is_valid value ', is_valid)

        if is_valid then
            propertyTable.bucketButtonEnabled = true
            propertyTable.validBucket = true
            propertyTable.bucketStatus = string.format('Bucket: %s', prefs.bucket)
            propertyTable.bucketNameTitle = LOC "$$$/Pixorist/BucketStatus/Status=Edit bucket"
            logger:trace('Bucket is valid woooo!')
        else
            propertyTable.validBucket = false
            propertyTable.bucketNameTitle = LOC "$$$/Pixorist/BucketStatus/Status=Edit bucket"
            propertyTable.bucketStatus = LOC( "$$$/Pixorist/BucketStatus/HasBucket=Invalid bucket")
            propertyTable.bucketStatus = "Invalid bucket"
        end
        doingBucket = false

    end )



end


function PixoristUser.add_keys( propertyTable )
    if not propertyTable.LR_editingExistingPublishConnection then
        noKeys( propertyTable )
    end

    require 'PixoristAPI'
    PixoristAPI.showApiKeyDialog()
    propertyTable.validKeys = true
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

function PixoristUser.verifyKeys( propertyTable )

    -- Observe changes to prefs and update status message accordingly.

    local function updateStatus()
        logger:trace( "verifyKeys: updateStatus() was triggered." )

        LrTasks.startAsyncTask( function()
            logger:trace( "verifyKeys: updateStatus() is executing." )
            if storedKeysAreValid( propertyTable ) then

                propertyTable.accountStatus = LOC( "$$$/Pixorist/AccountStatus/LoggedIn=Key pairs stored")
                propertyTable.keysButtonTitle = LOC "$$$/Pixorist/keysButton/LogInAgain=Edit keys"
                propertyTable.keysButtonEnabled = true
                propertyTable.validKeys = true
            else
                noKeys( propertyTable )
            end

        end )

    end

    propertyTable:addObserver( 'validKeys', updateStatus )
    updateStatus()

end


function PixoristUser.verifyBucket( propertyTable )

    -- Observe changes to prefs and update status message accordingly.

    local function updateStatus()

        LrTasks.startAsyncTask( function()
            logger:trace( "verifyBucket: updateStatus() is executing." )
            if storedBucketIsValid( propertyTable ) then

                propertyTable.bucketNameTitle = LOC "$$$/Pixorist/BucketButton/EditBucket=Edit bucket"
                propertyTable.bucketButtonEnabled = true
                propertyTable.validBucket = true
                propertyTable.bucketStatus = string.format('Bucket: %s', prefs.bucket)

            else
                logger:trace('bucket was not valid so clearing it')
                noBucket( propertyTable )
            end

        end )

    end

    propertyTable:addObserver( 'validBucket', updateStatus )
    updateStatus()

end
