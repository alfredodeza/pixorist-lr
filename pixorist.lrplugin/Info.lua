--[[----------------------------------------------------------------------------

Info.lua
Summary information for Pixorist plug-in

--------------------------------------------------------------------------------

 Copyright 2013 Alfredo Deza

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'com.adobe.lightroom.export.pixorist',
	LrPluginName = LOC "$$$/Pixorist/PluginName=Pixorist",

	LrExportServiceProvider = {
		title = LOC "$$$/Pixorist/Pixorist-title=Pixorist",
		file = 'PixoristExportServiceProvider.lua',
	},

    LrMetadataProvider = 'PixoristMetadataDefinition.lua',

	VERSION = { major=0, minor=0, revision=1, build=1, },

}
