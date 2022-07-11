--[[
Title: Keepwork Projects Api Filter
Author(s):  Big
Date: 2021.3.3
Desc: 
use the lib:
------------------------------------------------------------
local KeepworkProjectsApiFilter = NPL.load('(gl)Mod/WorldShare/filters/api/Keepwork/KeepworkProjectsApiFilter.lua')
KeepworkProjectsApiFilter:Init()
------------------------------------------------------------
]]

-- api
local KeepworkProjectsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectsApi.lua")

local KeepworkProjectsApiFilter = NPL.export()

function KeepworkProjectsApiFilter:Init()
    GameLogic.GetFilters():add_filter(
        'api.keepwork.projects.query_by_world_name_and_username',
        function(...)
            KeepworkProjectsApi:QueryByWorldNameAndUsername(...)
        end
    )
end