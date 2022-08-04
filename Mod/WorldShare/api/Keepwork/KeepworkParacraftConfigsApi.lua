--[[
Title: Keepwork Paracraft Configs API
Author(s): big
CreateDate: 2022.8.4
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkParacraftConfigsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkParacraftConfigsApi.lua")
------------------------------------------------------------
]]
local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkParacraftConfigsApi = NPL.export()

-- url: /paracraftConfigs
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkParacraftConfigsApi:ParacraftConfigs(success, error)
    KeepworkBaseApi:Get('/paracraftConfigs', nil, nil, success, error)
end