--[[
Title: User
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

local function setEmpty(value)
    if (not value) then
        value = nil
    end
end

setEmpty(WorldStore.worldDir)
setEmpty(WorldStore.foldername)
setEmpty(WorldStore.selectWorld)