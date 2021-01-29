--[[
Title: OnWorldInitialRegionsLoadedFilter
Author(s):  Big
Date: 2021.1.27
Desc: 
use the lib:
------------------------------------------------------------
local OnWorldInitialRegionsLoadedFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/OnWorldInitialRegionsLoadedFilter.lua')
OnWorldInitialRegionsLoadedFilter:Init()
------------------------------------------------------------
]]

-- commands
local WorldShareCommand = NPL.load("(gl)Mod/WorldShare/command/Command.lua")

local OnWorldInitialRegionsLoadedFilter = NPL.export()

function OnWorldInitialRegionsLoadedFilter:Init()
    GameLogic.GetFilters():add_filter(
        'OnWorldInitialRegionsLoaded',
        function()
            WorldShareCommand:ExecAfterLoadWorldCommands()

            return true
        end
    )
end