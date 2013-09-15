--[[----------------------------------------------------------------------------

PixoristMetadataDefinition.lua
Custom metadata definition for Pixorist publish plug-in

--------------------------------------------------------------------------------

(C) Copyright 2013 Alfredo Deza

------------------------------------------------------------------------------]]

return {

    metadataFieldsForPhotos = {
    
        {
            id = 'previous_tags',
            dataType = 'string',
        },

    },
    
    schemaVersion = 2, -- must be a number, preferably a positive integer
    
}
