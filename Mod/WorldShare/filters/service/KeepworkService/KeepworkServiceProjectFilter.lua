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
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')

local KeepworkServiceProjectFilter = NPL.export()

function KeepworkServiceProjectFilter:Init()
    -- filter is project read only
    GameLogic.GetFilters():add_filter(
        'service.keepwork_service_project.is_project_read_only',
        function(...)
            return KeepworkServiceProject:IsProjectReadOnly(...)
        end
    )
    -- get project info
    GameLogic.GetFilters():add_filter(
        'service.keepwork_service_project.get_project',
        function(kpProjectId,callback)
            KeepworkServiceProject:GetProject(kpProjectId,callback)
        end
    )
    -- update project info
    GameLogic.GetFilters():add_filter(
        'service.keepwork_service_project.update_project',
        function(kpProjectId,params,callback)
            KeepworkServiceProject:UpdateProject(kpProjectId, params, callback)
        end
    )
    -- remove project info
    GameLogic.GetFilters():add_filter(
        'service.keepwork_service_project.remove_project',
        function(kpProjectId,password,callback)
            KeepworkServiceProject:RemoveProject(kpProjectId, password, callback)
        end
    )
end
