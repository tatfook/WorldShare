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

local function SetEmpty(value)
    if (not value) then
        value = nil
    end
end

SetEmpty(WorldStore.worldDir)
SetEmpty(WorldStore.foldername)
SetEmpty(WorldStore.selectWorld)