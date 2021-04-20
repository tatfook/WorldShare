--[[
Title: Share World Filter
Author(s):  Big
Date: 2021.4.19
Desc: 
use the lib:
------------------------------------------------------------
local ShareWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/ShareWorld/ShareWorldFilter.lua')
ShareWorldFilter:Init()
------------------------------------------------------------
]]

-- UI
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")

local ShareWorldFilter = NPL.export()

function ShareWorldFilter:Init()
    -- show share world init page
    GameLogic.GetFilters():add_filter(
        'cellar.share_world.init',
        function(callback)
            ShareWorld:Init(callback)
        end
    )
end