--[[
Title: Keepwork Service Project Filter
Author(s):  Big
CreateDate: 2021.09.01
ModifyDate: 2021.09.14
Desc: 
use the lib:
------------------------------------------------------------
local KeepworkServiceWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/KeepworkServiceWorldFilter.lua')
KeepworkServiceWorldFilter:Init()
------------------------------------------------------------
]]

-- libs
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')

local KeepworkServiceWorldFilter = NPL.export()

function KeepworkServiceWorldFilter:Init()
    -- filter is project read only
    GameLogic.GetFilters():add_filter(
        'service.keepwork_service_world.set_world_instance_by_pid',
        function(...)
            return KeepworkServiceWorld:SetWorldInstanceByPid(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'service.keepwork_service_world.limit_free_user',
        function(...)
            return KeepworkServiceWorld:LimitFreeUser(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'OnCreateHomeWorld',
        function(...)
            KeepworkServiceWorld:OnCreateHomeWorld(...)
        end
    )
end
