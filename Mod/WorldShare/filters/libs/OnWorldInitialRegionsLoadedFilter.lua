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

local timer

function OnWorldInitialRegionsLoadedFilter:Init()
    GameLogic.GetFilters():add_filter(
        'OnLoadBlockRegion',
        function()
            if Mod.WorldShare.Store:Get('world/isLoadWorldCommandExec') then
                return
            end

            if not timer then
                timer = commonlib.Timer:new(
                    {
                        callbackFunc = function()
                            WorldShareCommand:ExecAfterLoadWorldCommands()
                            Mod.WorldShare.Store:Set('world/isLoadWorldCommandExec', true)
                            timer = nil
                        end
                    }
                )
                timer:Change(2000)
            else
                timer:Change(2000)
            end

            return true
        end
    )
end