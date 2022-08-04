--[[
Title: Keepwork Members API
Author(s): big
CreateDate: 2020.3.31
ModifyDate: 2022.8.4
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkPermissionsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkPermissionsApi.lua')
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkPermissionsApi = NPL.export()

-- /permissions/check?featureName=t_online_teaching
function KeepworkPermissionsApi:Check(featureName, success, error)
    if type(featureName) ~= "string" then
        return false
    end

    KeepworkBaseApi:Get('/permissions/check?featureName=' .. featureName, nil, nil, success, error)
end