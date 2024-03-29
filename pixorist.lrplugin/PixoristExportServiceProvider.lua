--[[----------------------------------------------------------------------------

PixoristExportServiceProvider.lua
Export service provider description for Lightroom Pixorist uploader

--------------------------------------------------------------------------------

(C) Copyright 2013 Alfredo Deza

------------------------------------------------------------------------------]]

    -- Lightroom SDK
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'
local logger = import 'LrLogger'( 'PixoristAPI' )
--logger:enable( 'logfile' )

    -- Common shortcuts
local bind = LrView.bind
local share = LrView.share

    -- Pixorist plug-in
require 'PixoristAPI'
require 'PixoristPublishSupport'


--============================================================================--

local exportServiceProvider = {}

-- A typical service provider would probably roll all of this into one file, but
-- this approach allows us to document the publish-specific hooks separately.

for name, value in pairs( PixoristPublishSupport ) do
    exportServiceProvider[ name ] = value
end

--------------------------------------------------------------------------------
-- We are publish only

exportServiceProvider.supportsIncrementalPublish = 'only'

--------------------------------------------------------------------------------
-- Some defaults that need cleanup

exportServiceProvider.exportPresetFields = {
    { key = 'username', default = "" },
    { key = 'fullname', default = "" },
    { key = 'nsid', default = "" },
    { key = 'isUserPro', default = false },
    { key = 'auth_token', default = '' },
    { key = 'privacy', default = 'public' },
    { key = 'privacy_family', default = false },
    { key = 'privacy_friends', default = false },
    { key = 'safety', default = 'safe' },
    { key = 'hideFromPublic', default = false },
    { key = 'type', default = 'photo' },
    { key = 'addToPhotoset', default = false },
    { key = 'photoset', default = '' },
    { key = 'titleFirstChoice', default = 'title' },
    { key = 'titleSecondChoice', default = 'filename' },
    { key = 'titleRepublishBehavior', default = 'replace' },
}

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value restricts the display of sections in the Export
 -- or Publish dialog to those named. You can use either <code>hideSections</code> or
 -- <code>showSections</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>exportLocation</li>
        -- <li>fileNaming</li>
        -- <li>fileSettings</li>
        -- <li>imageSettings</li>
        -- <li>outputSharpening</li>
        -- <li>metadata</li>
        -- <li>watermarking</li>
    -- </ul>
 -- <p>You cannot suppress display of the "Connection Name" section in the Publish Manager dialog.</p>
 -- <p>If you suppress the "exportLocation" section, the files are rendered into
 -- a temporary folder which is deleted immediately after the Export operation
 -- completes.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.showSections
    -- @class property

--exportServiceProvider.showSections = { 'fileNaming', 'fileSettings', etc... } -- not used for Pixorist plug-in

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value suppresses the display of the named sections in
 -- the Export or Publish dialogs. You can use either <code>hideSections</code> or
 -- <code>showSections</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>exportLocation</li>
        -- <li>fileNaming</li>
        -- <li>fileSettings</li>
        -- <li>imageSettings</li>
        -- <li>outputSharpening</li>
        -- <li>metadata</li>
        -- <li>watermarking</li>
    -- </ul>
 -- <p>You cannot suppress display of the "Connection Name" section in the Publish Manager dialog.</p>
 -- <p>If you suppress the "exportLocation" section, the files are rendered into
 -- a temporary folder which is deleted immediately after the Export operation
 -- completes.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.hideSections
    -- @class property

exportServiceProvider.hideSections = { 'exportLocation' }

--------------------------------------------------------------------------------
--- (optional, Boolean) If your plug-in allows the display of the exportLocation section,
 -- this property controls whether the item "Temporary folder" is available.
 -- If the user selects this option, the files are rendered into a temporary location
 -- on the hard drive, which is deleted when the export finished.
 -- <p>If your plug-in hides the exportLocation section, this temporary
 -- location behavior is always used.</p>
    -- @name exportServiceProvider.canExportToTemporaryLocation
    -- @class property

-- exportServiceProvider.canExportToTemporaryLocation = true -- not used for Pixorist plug-in

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value restricts the available file format choices in the
 -- Export or Publish dialogs to those named. You can use either <code>allowFileFormats</code> or
 -- <code>disallowFileFormats</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>JPEG</li>
        -- <li>PSD</li>
        -- <li>TIFF</li>
        -- <li>DNG</li>
        -- <li>ORIGINAL</li>
    -- </ul>
 -- <p>This property affects the output of still photo files only;
 -- it does not affect the output of video files.
 --  See <a href="#exportServiceProvider.canExportVideo"><code>canExportVideo</code></a>.)</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.allowFileFormats
    -- @class property

exportServiceProvider.allowFileFormats = { 'ORIGINAL' }

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value restricts the available color space choices in the
 -- Export or Publish dialogs to those named.  You can use either <code>allowColorSpaces</code> or
 -- <code>disallowColorSpaces</code>, but not both. If present, this should be an array
 -- containing one or more of the following strings:
    -- <ul>
        -- <li>sRGB</li>
        -- <li>AdobeRGB</li>
        -- <li>ProPhotoRGB</li>
    -- </ul>
 -- <p>Affects the output of still photo files only, not video files.
 -- See <a href="#exportServiceProvider.canExportVideo"><code>canExportVideo</code></a>.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.allowColorSpaces
    -- @class property

exportServiceProvider.allowColorSpaces = { 'sRGB' }

--------------------------------------------------------------------------------
--- (optional, Boolean) Plug-in defined value is true to hide print resolution controls
 -- in the Image Sizing section of the Export or Publish dialog.
 -- (Recommended when uploading to most web services.)
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @name exportServiceProvider.hidePrintResolution
    -- @class property

exportServiceProvider.hidePrintResolution = true

--------------------------------------------------------------------------------
-- Of course we want to be able to export video

exportServiceProvider.canExportVideo = true

--------------------------------------------------------------------------------

local function updateCantExportBecause( propertyTable )

    if not propertyTable.validKeys then
        propertyTable.LR_cantExportBecause = LOC "$$$/Pixorist/ExportDialog/NoLogin=Incomplete Pixorist account setup: missing or invalid API key"
    elseif not propertyTable.validUsername then
        propertyTable.LR_cantExportBecause = LOC "$$$/Pixorist/ExportDialog/NoLogin=Incomplete Pixorist account setup: missing or invalid username"
    else
        propertyTable.LR_cantExportBecause = nil
    end
end

local displayNameForTitleChoice = {
    filename = LOC "$$$/Pixorist/ExportDialog/Title/Filename=Filename",
    title = LOC "$$$/Pixorist/ExportDialog/Title/Title=IPTC Title",
    empty = LOC "$$$/Pixorist/ExportDialog/Title/Empty=Leave Blank",
}

local kSafetyTitles = {
    safe = LOC "$$$/Pixorist/ExportDialog/Safety/Safe=Safe",
    moderate = LOC "$$$/Pixorist/ExportDialog/Safety/Moderate=Moderate",
    restricted = LOC "$$$/Pixorist/ExportDialog/Safety/Restricted=Restricted",
}

local function booleanToNumber( value )

    return value and 1 or 0

end

local privacyToNumber = {
    private = 0,
    public = 1,
}

local safetyToNumber = {
    safe = 1,
    moderate = 2,
    restricted = 3,
}

local contentTypeToNumber = {
    photo = 1,
    screenshot = 2,
    other = 3,
}

local function getPixoristTitle( photo, exportSettings, pathOrMessage )

    local title

    -- Get title according to the options in Pixorist Title section.

    if exportSettings.titleFirstChoice == 'filename' then

        title = LrPathUtils.leafName( pathOrMessage )

    elseif exportSettings.titleFirstChoice == 'title' then

        title = photo:getFormattedMetadata 'title'

        if ( not title or #title == 0 ) and exportSettings.titleSecondChoice == 'filename' then
            title = LrPathUtils.leafName( pathOrMessage )
        end

    end

    return title

end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the
 -- user chooses this export service provider in the Export or Publish dialog,
 -- or when the destination is already selected when the dialog is invoked,
 -- (remembered from the previous export operation).
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param propertyTable (table) An observable table that contains the most
        -- recent settings for your export or publish plug-in, including both
        -- settings that you have defined and Lightroom-defined export settings
    -- @name exportServiceProvider.startDialog
    -- @class function

function exportServiceProvider.startDialog( propertyTable )

    -- Clear login if it's a new connection.
    local prefs = import 'LrPrefs'.prefsForPlugin()

    if not propertyTable.LR_editingExistingPublishConnection then
        prefs.apiKey = nil
        prefs.username = nil
    end

    -- Can't export until we've validated the login.

    propertyTable:addObserver( 'validKeys', function() updateCantExportBecause( propertyTable ) end )
    propertyTable:addObserver( 'validUsername', function() updateCantExportBecause( propertyTable ) end )
    updateCantExportBecause( propertyTable )

    -- Make sure we're logged in.

    require 'PixoristUser'
    PixoristUser.verifyCredentials( propertyTable )

end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- chooses this export service provider in the Export or Publish dialog.
 -- It can create new sections that appear above all of the built-in sections
 -- in the dialog (except for the Publish Service section in the Publish dialog,
 -- which always appears at the very top).
 -- <p>Your plug-in's <a href="#exportServiceProvider.startDialog"><code>startDialog</code></a>
 -- function, if any, is called before this function is called.</p>
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param f (<a href="LrView.html#LrView.osFactory"><code>LrView.osFactory</code> object)
        -- A view factory object.
    -- @param propertyTable (table) An observable table that contains the most
        -- recent settings for your export or publish plug-in, including both
        -- settings that you have defined and Lightroom-defined export settings
    -- @return (table) An array of dialog sections (see example code for details)
    -- @name exportServiceProvider.sectionsForTopOfDialog
    -- @class function

function exportServiceProvider.sectionsForTopOfDialog( f, propertyTable )

    return {

        {
            title = LOC "$$$/Pixorist/ExportDialog/Account=Pixorist Account",

            synopsis = bind 'accountStatus',

            f:row {
                spacing = f:control_spacing(),

                f:static_text {
                    title = bind 'credentialsStatus',
                    alignment = 'left',
                    fill_horizontal = 1,
                },

                f:push_button {
                    width = tonumber( LOC "$$$/locale_metric/Pixorist/ExportDialog/credentialsButton/Width=140" ),
                    title = bind 'credentialsNameTitle',
                    enabled = true,
                    action = function()
                    require 'PixoristUser'
                    PixoristUser.add_credentials( propertyTable )
                    end,
                },
            },

        },

        {
            title = LOC "$$$/Pixorist/ExportDialog/Title=Pixorist Title",

            synopsis = function( props )
                if props.titleFirstChoice == 'title' then
                    return LOC( "$$$/Pixorist/ExportDialog/Synopsis/TitleWithFallback=IPTC Title or ^1", displayNameForTitleChoice[ props.titleSecondChoice ] )
                else
                    return props.titleFirstChoice and displayNameForTitleChoice[ props.titleFirstChoice ] or ''
                end
            end,

            f:column {
                spacing = f:control_spacing(),

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = LOC "$$$/Pixorist/ExportDialog/ChooseTitleBy=Set Pixorist Title Using:",
                        alignment = 'right',
                        width = share 'flickrTitleSectionLabel',
                    },

                    f:popup_menu {
                        value = bind 'titleFirstChoice',
                        width = share 'flickrTitleLeftPopup',
                        items = {
                            { value = 'filename', title = displayNameForTitleChoice.filename },
                            { value = 'title', title = displayNameForTitleChoice.title },
                            { value = 'empty', title = displayNameForTitleChoice.empty },
                        },
                    },

                    f:spacer { width = 20 },

                    f:static_text {
                        title = LOC "$$$/Pixorist/ExportDialog/ChooseTitleBySecondChoice=If Empty, Use:",
                        enabled = LrBinding.keyEquals( 'titleFirstChoice', 'title', propertyTable ),
                    },

                    f:popup_menu {
                        value = bind 'titleSecondChoice',
                        enabled = LrBinding.keyEquals( 'titleFirstChoice', 'title', propertyTable ),
                        items = {
                            { value = 'filename', title = displayNameForTitleChoice.filename },
                            { value = 'empty', title = displayNameForTitleChoice.empty },
                        },
                    },
                },

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = LOC "$$$/Pixorist/ExportDialog/OnUpdate=When Updating Photos:",
                        alignment = 'right',
                        width = share 'flickrTitleSectionLabel',
                    },

                    f:popup_menu {
                        value = bind 'titleRepublishBehavior',
                        width = share 'flickrTitleLeftPopup',
                        items = {
                            { value = 'replace', title = LOC "$$$/Pixorist/ExportDialog/ReplaceExistingTitle=Replace Existing Title" },
                            { value = 'leaveAsIs', title = LOC "$$$/Pixorist/ExportDialog/LeaveAsIs=Leave Existing Title" },
                        },
                    },
                },
            },
        },
    }

end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- chooses this export service provider in the Export or Publish dialog.
 -- It can create new sections that appear below all of the built-in sections in the dialog.
 -- <p>Your plug-in's <a href="#exportServiceProvider.startDialog"><code>startDialog</code></a>
 -- function, if any, is called before this function is called.</p>
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param f (<a href="LrView.html#LrView.osFactory"><code>LrView.osFactory</code> object)
        -- A view factory object
    -- @param propertyTable (table) An observable table that contains the most
        -- recent settings for your export or publish plug-in, including both
        -- settings that you have defined and Lightroom-defined export settings
    -- @return (table) An array of dialog sections (see example code for details)
    -- @name exportServiceProvider.sectionsForBottomOfDialog
    -- @class function

-- TODO: It would be nice to enable this at some point since Pixorist allows
-- us to controll privacy
--function exportServiceProvider.sectionsForBottomOfDialog( f, propertyTable )
--
--  return {
--
--      {
--          title = LOC "$$$/Pixorist/ExportDialog/PrivacyAndSafety=Privacy and Safety",
--          synopsis = function( props )
--
--              local summary = {}
--
--              local function add( x )
--                  if x then
--                      summary[ #summary + 1 ] = x
--                  end
--              end
--
--              if props.privacy == 'private' then
--                  add( LOC "$$$/Pixorist/ExportDialog/Private=Private" )
--                  if props.privacy_family then
--                      add( LOC "$$$/Pixorist/ExportDialog/Family=Family" )
--                  end
--                  if props.privacy_friends then
--                      add( LOC "$$$/Pixorist/ExportDialog/Friends=Friends" )
--                  end
--              else
--                  add( LOC "$$$/Pixorist/ExportDialog/Public=Public" )
--              end
--
--              local safetyStr = kSafetyTitles[ props.safety ]
--              if safetyStr then
--                  add( safetyStr )
--              end
--
--              return table.concat( summary, " / " )
--
--          end,
--
--          place = 'horizontal',
--
--          f:column {
--              spacing = f:control_spacing() / 2,
--              fill_horizontal = 1,
--
--              f:row {
--                  f:static_text {
--                      title = LOC "$$$/Pixorist/ExportDialog/Privacy=Privacy:",
--                      alignment = 'right',
--                      width = share 'labelWidth',
--                  },
--
--                  f:radio_button {
--                      title = LOC "$$$/Pixorist/ExportDialog/Private=Private",
--                      checked_value = 'private',
--                      value = bind 'privacy',
--                  },
--              },
--
--              f:row {
--                  f:spacer {
--                      width = share 'labelWidth',
--                  },
--
--                  f:column {
--                      spacing = f:control_spacing() / 2,
--                      margin_left = 15,
--                      margin_bottom = f:control_spacing() / 2,
--
--                      f:checkbox {
--                          title = LOC "$$$/Pixorist/ExportDialog/Family=Family",
--                          value = bind 'privacy_family',
--                          enabled = LrBinding.keyEquals( 'privacy', 'private' ),
--                      },
--
--                      f:checkbox {
--                          title = LOC "$$$/Pixorist/ExportDialog/Friends=Friends",
--                          value = bind 'privacy_friends',
--                          enabled = LrBinding.keyEquals( 'privacy', 'private' ),
--                      },
--                  },
--              },
--
--              f:row {
--                  f:spacer {
--                      width = share 'labelWidth',
--                  },
--
--                  f:radio_button {
--                      title = LOC "$$$/Pixorist/ExportDialog/Public=Public",
--                      checked_value = 'public',
--                      value = bind 'privacy',
--                  },
--              },
--          },
--
--          f:column {
--              spacing = f:control_spacing() / 2,
--
--              fill_horizontal = 1,
--
--              f:row {
--                  f:static_text {
--                      title = LOC "$$$/Pixorist/ExportDialog/Safety=Safety:",
--                      alignment = 'right',
--                      width = share 'flickr_col2_label_width',
--                  },
--
--                  f:popup_menu {
--                      value = bind 'safety',
--                      width = share 'flickr_col2_popup_width',
--                      items = {
--                          { title = kSafetyTitles.safe, value = 'safe' },
--                          { title = kSafetyTitles.moderate, value = 'moderate' },
--                          { title = kSafetyTitles.restricted, value = 'restricted' },
--                      },
--                  },
--              },
--
--              f:row {
--                  margin_bottom = f:control_spacing() / 2,
--
--                  f:spacer {
--                      width = share 'flickr_col2_label_width',
--                  },
--
--                  f:checkbox {
--                      title = LOC "$$$/Pixorist/ExportDialog/HideFromPublicSite=Hide from public site areas",
--                      value = bind 'hideFromPublic',
--                  },
--              },
--
--              f:row {
--                  f:static_text {
--                      title = LOC "$$$/Pixorist/ExportDialog/Type=Type:",
--                      alignment = 'right',
--                      width = share 'flickr_col2_label_width',
--                  },
--
--                  f:popup_menu {
--                      width = share 'flickr_col2_popup_width',
--                      value = bind 'type',
--                      items = {
--                          { title = LOC "$$$/Pixorist/ExportDialog/Type/Photo=Photo", value = 'photo' },
--                          { title = LOC "$$$/Pixorist/ExportDialog/Type/Screenshot=Screenshot", value = 'screenshot' },
--                          { title = LOC "$$$/Pixorist/ExportDialog/Type/Other=Other", value = 'other' },
--                      },
--                  },
--              },
--          },
--      },
--  }
--
--end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called for each exported photo
 -- after it is rendered by Lightroom and after all post-process actions have been
 -- applied to it. This function is responsible for transferring the image file
 -- to its destination, as defined by your plug-in. The function that
 -- you define is launched within a cooperative task that Lightroom provides. You
 -- do not need to start your own task to run this function; and in general, you
 -- should not need to start another task from within your processing function.
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
    -- @param functionContext (<a href="LrFunctionContext.html"><code>LrFunctionContext</code></a>)
        -- function context that you can use to attach clean-up behaviors to this
        -- process; this function context terminates as soon as your function exits.
    -- @param exportContext (<a href="LrExportContext.html"><code>LrExportContext</code></a>)
        -- Information about your export settings and the photos to be published.

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )

    local exportSession = exportContext.exportSession

    -- Make a local reference to the export parameters.

    local exportSettings = assert( exportContext.propertyTable )

    -- Get the # of photos.

    local nPhotos = exportSession:countRenditions()

    -- Set progress title.

    local progressScope = exportContext:configureProgress {
                        title = nPhotos > 1
                                    and LOC( "$$$/Pixorist/Publish/Progress=Publishing ^1 photos to Pixorist", nPhotos )
                                    or LOC "$$$/Pixorist/Publish/Progress/One=Publishing one photo to Pixorist",
                    }

    -- Save off uploaded photo IDs so we can take user to those photos later.

    local uploadedPhotoIds = {}

    local publishedCollectionInfo = exportContext.publishedCollectionInfo

    local isDefaultCollection = publishedCollectionInfo.isDefaultCollection

    -- Look for a photoset id for this collection.

    local photosetId = publishedCollectionInfo.remoteId

    -- Get a list of photos already in this photoset so we know which ones we can replace and which have
    -- to be re-uploaded entirely.

    local photosetPhotoIds = photosetId and PixoristAPI.listPhotosFromPhotoset( exportSettings, { photosetId = photosetId } )

    local photosetPhotosSet = {}

    -- Turn it into a set for quicker access later.

    if photosetPhotoIds then
        for _, id in ipairs( photosetPhotoIds ) do
            photosetPhotosSet[ id ] = true
        end
    end

    local couldNotPublishBecauseFreeAccount = {}
    local flickrPhotoIdsForRenditions = {}

    local cannotRepublishCount = 0

    -- Gather flickr photo IDs, and if we're on a free account, remember the renditions that
    -- had been previously published.

    for i, rendition in exportContext.exportSession:renditions() do

        local flickrPhotoId = rendition.publishedPhotoId
        logger:trace('iterating over id ' , flickrPhotoId)

        if flickrPhotoId then
            logger:trace('found this id had been published ' , flickrPhotoId)
            logger:trace('XXX should make sure to check if it exists in Pixorist' , flickrPhotoId)

            -- Check to see if the photo is still on Pixorist.

            --if not photosetPhotosSet[ flickrPhotoId ] and not isDefaultCollection then
            --  flickrPhotoId = nil
            --end

        end


        flickrPhotoIdsForRenditions[ rendition ] = flickrPhotoId
        logger:trace('Setting this id for renditions ', flickrPhotoId)

    end

    -- If we're on a free account, see which photos are being republished and give a warning.

    if cannotRepublishCount > 0 then
        logger:trace('we should not be here, it means cannotReplishCount is more than 1')

        local message = ( cannotRepublishCount == 1 ) and
                            LOC( "$$$/Pixorist/FreeAccountErr/Singular/ThereIsAPhotoToUpdateOnPixorist=There is one photo to update on Pixorist" )
                            or LOC( "$$$/Pixorist/FreeAccountErr/Plural/ThereIsAPhotoToUpdateOnPixorist=There are ^1 photos to update on Pixorist", cannotRepublishCount )

        local messageInfo = LOC( "$$$/Pixorist/FreeAccountErr/Singular/CommentsAndRatingsWillBeLostWarning=With a free (non-Pro) Pixorist account, all comments and ratings will be lost on updated photos. Are you sure you want to do this?" )

        local action = LrDialogs.promptForActionWithDoNotShow {
                                    message = message,
                                    info = messageInfo,
                                    actionPrefKey = "nonProRepublishWarning",
                                    verbBtns = {
                                        { label = LOC( "$$$/Pixorist/Dialog/Buttons/FreeAccountErr/Skip=Skip" ), verb = "skip", },
                                        { label = LOC( "$$$/Pixorist/Dialog/Buttons/FreeAccountErr/Replace=Replace" ), verb = "replace", },
                                    }
                                }

        if action == "skip" then

            local skipRendition = next( couldNotPublishBecauseFreeAccount )

            while skipRendition ~= nil do
                skipRendition:skipRender()
                skipRendition = next( couldNotPublishBecauseFreeAccount, skipRendition )
            end

        elseif action == "replace" then

            -- We will publish as usual, replacing these photos.

            couldNotPublishBecauseFreeAccount = {}

        else

            -- User canceled

            progressScope:done()
            return

        end

    end

    -- Iterate through photo renditions.

    local photosetUrl

    for i, rendition in exportContext:renditions { stopIfCanceled = true } do

        -- Update progress scope.

        progressScope:setPortionComplete( ( i - 1 ) / nPhotos )

        -- Get next photo.

        local photo = rendition.photo

        -- See if we previously uploaded this photo.

        local flickrPhotoId = flickrPhotoIdsForRenditions[ rendition ]
        logger:trace('flickrPhotoId ', flickrPhotoId)
        if not rendition.wasSkipped then

            local success, pathOrMessage = rendition:waitForRender()
            local exportParams = exportContext.propertyTable

            logger:trace('filepath created ', pathOrMessage)
            logger:trace('Success from rendition ', success)

            -- Update progress scope again once we've got rendered photo.

            progressScope:setPortionComplete( ( i - 0.5 ) / nPhotos )

            -- Check for cancellation again after photo has been rendered.

            if progressScope:isCanceled() then break end

            if success then

                -- Build up common metadata for this photo.

                --local title = getPixoristTitle( photo, exportSettings, pathOrMessage )

                --local description = photo:getFormattedMetadata( 'caption' )
                --local keywordTags = photo:getFormattedMetadata( 'keywordTagsForExport' )

                --local tags

                --if keywordTags then

                --  tags = {}

                --  local keywordIter = string.gfind( keywordTags, "[^,]+" )

                --  for keyword in keywordIter do

                --      if string.sub( keyword, 1, 1 ) == ' ' then
                --          keyword = string.sub( keyword, 2, -1 )
                --      end

                --      if string.find( keyword, ' ' ) ~= nil then
                --          keyword = '"' .. keyword .. '"'
                --      end

                --      tags[ #tags + 1 ] = keyword

                --  end

                --end

                ---- Pixorist will pick up LR keywords from XMP, so we don't need to merge them here.

                --local is_public = privacyToNumber[ exportSettings.privacy ]
                --local is_friend = booleanToNumber( exportSettings.privacy_friends )
                --local is_family = booleanToNumber( exportSettings.privacy_family )
                --local safety_level = safetyToNumber[ exportSettings.safety ]
                --local content_type = contentTypeToNumber[ exportSettings.type ]
                --local hidden = exportSettings.hideFromPublic and 2 or 1

                ---- Because it is common for Pixorist users (even viewers) to add additional tags via
                ---- the Pixorist web site, so we should not remove extra keywords that do not correspond
                ---- to keywords in Lightroom. In order to do so, we record the tags that we uploaded
                ---- this time. Next time, we will compare the previous tags with these current tags.
                ---- We use the difference between tag sets to determine if we should remove a tag (i.e.
                ---- it was one we uploaded and is no longer present in Lightroom) or not (i.e. it was
                ---- added by user on Pixorist and never was present in Lightroom).

                --local previous_tags = photo:getPropertyForPlugin( _PLUGIN, 'previous_tags' )

                ---- If on a free account and this photo already exists, delete it from Pixorist.

                --if flickrPhotoId and not exportSettings.isUserPro then

                --  PixoristAPI.deletePhoto( exportSettings, { photoId = flickrPhotoId, suppressError = true } )
                --  flickrPhotoId = nil

                --end

                ---- Upload or replace the photo.

                --local didReplace = not not flickrPhotoId

                PixoristAPI.uploadPhoto( exportSettings, {
                                    photo_id = flickrPhotoId,
                                    filePath = pathOrMessage,
                                    title = title or '',
                                    description = description,
                                    tags = '',
                                    is_public = is_public,
                                    is_friend = is_friend,
                                    is_family = is_family,
                                    safety_level = safety_level,
                                    content_type = content_type,
                                    hidden = hidden,
                                } )
                -- FIXME: we need to probably do better here. A filename can't
                -- be really the whole ID. Come on now
                local fileName = LrPathUtils.leafName( pathOrMessage )
                flickrPhotoId = fileName

                --if didReplace then

                --  -- The replace call used by PixoristAPI.uploadPhoto ignores all of the metadata that is passed
                --  -- in above. We have to manually upload that info after the fact in this case.

                --  if exportSettings.titleRepublishBehavior == 'replace' then

                --      PixoristAPI.callRestMethod( exportSettings, {
                --                              method = 'flickr.photos.setMeta',
                --                              photo_id = flickrPhotoId,
                --                              title = title or '',
                --                              description = description or '',
                --                          } )

                --  end

                --  PixoristAPI.callRestMethod( exportSettings, {
                --                          method = 'flickr.photos.setPerms',
                --                          photo_id = flickrPhotoId,
                --                          is_public = is_public,
                --                          is_friend = is_friend,
                --                          is_family = is_family,
                --                          perm_comment = 3, -- everybody
                --                          perm_addmeta = 3, -- everybody
                --                      } )

                --  PixoristAPI.callRestMethod( exportSettings, {
                --                          method = 'flickr.photos.setSafetyLevel',
                --                          photo_id = flickrPhotoId,
                --                          safety_level = safety_level,
                --                          hidden = (hidden == 2) and 1 or 0,
                --                      } )

                --  PixoristAPI.callRestMethod( exportSettings, {
                --                          method = 'flickr.photos.setContentType',
                --                          photo_id = flickrPhotoId,
                --                          content_type = content_type,
                --                      } )

                --end

                --PixoristAPI.setImageTags( exportSettings, {
                --                          photo_id = flickrPhotoId,
                --                          tags = table.concat( tags, ',' ),
                --                          previous_tags = previous_tags,
                --                          is_public = is_public,
                --                      } )

                -- When done with photo, delete temp file. There is a cleanup step that happens later,
                -- but this will help manage space in the event of a large upload.

                -- XXX DANGEROUS TO COMMENT OUT, make sure to remove.
                LrFileUtils.delete( pathOrMessage )

                -- Remember this in the list of photos we uploaded.

                uploadedPhotoIds[ #uploadedPhotoIds + 1 ] = flickrPhotoId

                -- If this isn't the Photostream, set up the photoset.

                --if not photosetUrl then

                --  if not isDefaultCollection then

                --      -- Create or update this photoset.

                --      photosetId, photosetUrl = PixoristAPI.createOrUpdatePhotoset( exportSettings, {
                --                                  photosetId = photosetId,
                --                                  title = publishedCollectionInfo.name,
                --                                  --      description = ??,
                --                                  primary_photo_id = uploadedPhotoIds[ 1 ],
                --                              } )

                --  else

                --      -- Photostream: find the URL.

                --      photosetUrl = PixoristAPI.constructPhotostreamURL( exportSettings )

                --  end

                --end

                -- Record this Pixorist ID with the photo so we know to replace instead of upload.

                rendition:recordPublishedPhotoId( flickrPhotoId )

                --local photoUrl

                --if ( not isDefaultCollection ) then

                --  photoUrl = PixoristAPI.constructPhotoURL( exportSettings, {
                --                          photo_id = flickrPhotoId,
                --                          photosetId = photosetId,
                --                          is_public = is_public,
                --                      } )

                --  -- Add the uploaded photos to the correct photoset.

                --  PixoristAPI.addPhotosToSet( exportSettings, {
                --                  photoId = flickrPhotoId,
                --                  photosetId = photosetId,
                --              } )

                --else

                --  photoUrl = PixoristAPI.constructPhotoURL( exportSettings, {
                --                          photo_id = flickrPhotoId,
                --                          is_public = is_public,
                --                      } )

                --end

                --rendition:recordPublishedPhotoUrl( photoUrl )

                -- Because it is common for Pixorist users (even viewers) to add additional tags
                -- via the Pixorist web site, so we can avoid removing those user-added tags that
                -- were never in Lightroom to begin with. See earlier comment.

                --photo.catalog:withPrivateWriteAccessDo( function()
                --                      photo:setPropertyForPlugin( _PLUGIN, 'previous_tags', table.concat( tags, ',' ) )
                --                  end )

            end

        else

            -- To get the skipped photo out of the to-republish bin.
            rendition:recordPublishedPhotoId(rendition.publishedPhotoId)

        end

    end

    progressScope:done()

end

--------------------------------------------------------------------------------

return exportServiceProvider
