--[[
Title: Keepwork Worlds API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkWorldsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Worlds.lua")
------------------------------------------------------------
]]
local Encoding = commonlib.gettable("commonlib.Encoding")

local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkWorldsApi = NPL.export()

-- url: /worlds
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkWorldsApi:GetWorldList(success, error)
    local url = '/worlds'

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /worlds?worldName=%s
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkWorldsApi:GetWorldByName(foldername, success, error)
    local url = format("/worlds?worldName=%s", Encoding.url_encode(foldername or ''))

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /worlds/%s
-- method: PUT
-- return: object
function KeepworkWorldsApi:UpdateWorldinfo(worldId, params, success, error)
    if type(worldId) ~= 'number' or type(params) ~= 'table' then
        return false
    end

    local url = format("/worlds/%s", worldId)

    KeepworkBaseApi:Put(url, params, nil, success, error)
end