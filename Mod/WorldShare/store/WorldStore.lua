--[[
Title: world store
Author(s): big
Date: 2018.8.24
City: Foshan 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/store/WorldStore.lua")
local WorldStore = commonlib.gettable('Mod.WorldShare.store.World')
------------------------------------------------------------
]]

local WorldStore = commonlib.gettable('Mod.WorldShare.store.World')

function WorldStore:Action()
    return {
        ClearSelectWorld = function() end
    }
end

function WorldStore:Getter()
    return {
        
    }
end