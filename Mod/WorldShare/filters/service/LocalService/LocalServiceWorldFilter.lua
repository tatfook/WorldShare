--[[
Title: Local Service World Filter
Author(s):  Big
Date: 2020.12.11
Desc: 
use the lib:
------------------------------------------------------------
local LocalServiceWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/service/LocalService/LocalServiceWorldFilter.lua')
LocalServiceWorldFilter:Init()
------------------------------------------------------------
]]

-- service
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')

local LocalServiceWorldFilter = NPL.export()

function LocalServiceWorldFilter:Init()
    GameLogic.GetFilters():add_filter(
        'service.local_service_world.is_community_world',
        function()
            return LocalServiceWorld:IsCommunityWorld()
        end
    )

    -- filter set community world
    GameLogic.GetFilters():add_filter(
        'service.local_service_world.set_community_world',
        function(bValue)
            LocalServiceWorld:SetCommunityWorld(bValue)
        end
    )

    -- filter set_world_instance_by_foldername
    GameLogic.GetFilters():add_filter(
        'service.local_service_world.set_world_instance_by_foldername',
        function(...)
            LocalServiceWorld:SetWorldInstanceByFoldername(...)
        end
    )
end
