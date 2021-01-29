--[[
Title: WorlfInfoFilter
Author(s):  Big
Date: 2021.1.27
Desc: 
use the lib:
------------------------------------------------------------
local WorlfInfoFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/WorlfInfoFilter.lua')
WorlfInfoFilter:Init()
------------------------------------------------------------
]]

-- libs
local LocalServiceWorld = NPL.load("(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua")

local WorldInfoFilter = NPL.export()

function WorldInfoFilter:Init()
    -- replace implement save world event
    GameLogic.GetFilters():add_filter(
        'save_world_info',
        function(ctx, node)
            LocalServiceWorld:SaveWorldInfo(ctx, node)
        end
    )
end