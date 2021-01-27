--[[
Title: OnLoadBlockRegionFilter
Author(s):  Big
Date: 2021.1.27
Desc: 
use the lib:
------------------------------------------------------------
local OnLoadBlockRegionFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/OnLoadBlockRegionFilter.lua')
OnLoadBlockRegionFilter:Init()
------------------------------------------------------------
]]

-- commands
local WorldShareCommand = NPL.load("(gl)Mod/WorldShare/command/Command.lua")

local OnLoadBlockRegionFilter = NPL.export()

local timer

function OnLoadBlockRegionFilter:Init()
    GameLogic.GetFilters():add_filter(
        'OnLoadBlockRegion',
        function()
            if not timer then
                timer = commonlib.Timer:new(
                    {
                        callbackFunc = function()
                            WorldShareCommand:ExecAfterLoadWorldCommands()
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