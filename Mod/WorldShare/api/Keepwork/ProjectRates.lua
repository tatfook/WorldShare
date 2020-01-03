--[[
Title: Keepwork ProjectRates API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkProjectsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/ProjectRates.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkProjectsApi = NPL.export()

-- url: /projectRates?projectId=%d
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkProjectsApi:GetRatedProject(kpProjectId, success, error)
    if type(kpProjectId) ~= 'number' then
        return false
    end

    local url = format('/projectRates?projectId=%d', kpProjectId)

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /projectRates
-- method: POST
-- params:
--[[
]]
-- return: object
function KeepworkProjectsApi:CreateProjectRates(params, success, error)
    local url = '/projectRates'

    KeepworkBaseApi:Post(url, params, nil, success, error)
end

-- url: /projectRates/%d
-- method: PUT
-- params:
-- [[]]
-- return: object
function KeepworkProjectsApi:UpdateProjectRates(kpProjectId, params, success, error)
    if type(kpProjectId) ~= 'number' then
        return false
    end

    local url = format('/projectRates/%d', kpProjectId)

    KeepworkBaseApi:Put(url, params, nil, success, error)
end