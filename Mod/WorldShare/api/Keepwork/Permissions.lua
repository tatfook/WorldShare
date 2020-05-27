--[[
Title: Keepwork Members API
Author(s):  big
Date:  2020.03.31
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkPermissionsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Permissions.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkPermissionsApi = NPL.export()

-- /permissions/check?featureName=t_online_teaching
function KeepworkPermissionsApi:Check(featureName, success, error)
    if type(featureName) ~= "string" then
        return false
    end

    KeepworkBaseApi:Get("/permissions/check?featureName=" .. featureName, nil, nil, success, error)
end