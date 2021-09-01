--[[
Title: Keepwork Service Project Filter
Author(s):  Big
Date: 2021.9.1
Desc: 
use the lib:
------------------------------------------------------------
local KeepworkServiceProjectFilter = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/KeepworkServiceProjectFilter.lua')
KeepworkServiceProjectFilter:Init()
------------------------------------------------------------
]]

-- libs
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')

local KeepworkServiceProjectFilter = NPL.export()

function KeepworkServiceProjectFilter:init()
    -- filter is project read only
    GameLogic.GetFilters():add_filter(
        'service.keepwork_service_project.is_project_read_only',
        function(...)
            return KeepworkServiceProject:IsProjectReadOnly(...)
        end
    )
end
