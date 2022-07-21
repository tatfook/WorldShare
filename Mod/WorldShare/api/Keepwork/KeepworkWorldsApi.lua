--[[
Title: Keepwork Worlds API
Author(s): big
CreateDate: 2019.11.8
ModifyDate: 2022.7.11
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkWorldsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkWorldsApi.lua')
------------------------------------------------------------
]]
local Encoding = commonlib.gettable('commonlib.Encoding')

local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkWorldsApi = NPL.export()

-- url: /worlds
-- method: GET
-- params:
--[[
    x-page
    x-per-page
]]
-- return: object
function KeepworkWorldsApi:GetWorldList(xPerPage, xPage, success, error)
    local url = '/joinedWorlds'

    if type(xPerPage) == 'number' then
        url = url .. '?x-per-page=' .. xPerPage

        if type(xPerPage) == 'number' then
            url = url .. '&x-page=' .. xPage
        end
    end

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /joinedWorlds?worldName=%s
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkWorldsApi:GetWorldByName(foldername, success, error)
    local url = format('/joinedWorlds?worldName=%s', Encoding.url_encode(foldername or ''))

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /worlds/%s
-- method: PUT
-- return: object
function KeepworkWorldsApi:UpdateWorldInfo(worldId, params, success, error)
    if not worldId or
       type(worldId) ~= 'number' or
       not params or
       type(params) ~= 'table' then
        return
    end

    local url = format('/worlds/%s', worldId)

    KeepworkBaseApi:Put(url, params, nil, success, error)
end