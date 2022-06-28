--[[
Title: world store
Author(s): big
CreateDate: 2018.8.24
ModifyDate: 2022.6.28
City: Foshan 
use the lib:
------------------------------------------------------------
local WorldStore = NPL.load('(gl)Mod/WorldShare/store/WorldStore.lua')
------------------------------------------------------------
]]

local WorldStore = NPL.export()

function WorldStore:Action(data)
    local self = data

    return {
        ClearSelectWorld = function() end
    }
end

function WorldStore:Getter(data)
    local self = data

    return {
        GetWorldTextName = function()
            if self.currentWorld and self.currentWorld.text then
                return self.currentWorld.text
            else
                return ''
            end
        end
    }
end