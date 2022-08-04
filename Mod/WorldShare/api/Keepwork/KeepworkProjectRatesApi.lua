--[[
Title: Keepwork ProjectRates API
Author(s): big
CreateDate: 2019.11.8
ModifyDate: 2022.8.4
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkProjectRatesApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectRatesApi.lua')
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkProjectRatesApi = NPL.export()

-- url: /projectRates?projectId=%d
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkProjectRatesApi:GetRatedProject(kpProjectId, success, error)
    if not kpProjectId or type(kpProjectId) ~= 'number' then
        return
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
function KeepworkProjectRatesApi:CreateProjectRates(params, success, error)
    local url = '/projectRates'

    KeepworkBaseApi:Post(url, params, nil, success, error)
end

-- url: /projectRates/%d
-- method: PUT
-- params:
-- [[]]
-- return: object
function KeepworkProjectRatesApi:UpdateProjectRates(kpProjectId, params, success, error)
    if not kpProjectId or type(kpProjectId) ~= 'number' then
        return
    end

    local url = format('/projectRates/%d', kpProjectId)

    KeepworkBaseApi:Put(url, params, nil, success, error)
end