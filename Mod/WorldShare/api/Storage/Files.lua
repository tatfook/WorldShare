--[[
Title: Storage Files API
Author(s):  big
Date:  2019.12.16
Place: Foshan
use the lib:
------------------------------------------------------------
local StorageFilesApi = NPL.load("(gl)Mod/WorldShare/api/Storage/Files.lua")
------------------------------------------------------------
]]

local StorageBaseApi = NPL.load('./BaseApi.lua')

local StorageFilesApi = NPL.export()

-- url: /files/:key/token
-- method: GET
-- params: key string
-- return: object
function StorageFilesApi:Token(filename, success, error)
    local ext = string.match(filename, '.+%.(%S+)$')

    if type(ext) ~= 'string' then
        return false
    end

    local uuid = System.Encoding.guid.uuid()
    local userId = Mod.WorldShare.Store:Get('user/userId')
    local key = format('%s-%s.%s', userId, uuid, ext)

    local url = format('/files/%s/token', key)

    StorageBaseApi:Get(url, nil, nil, function(data, err)
        if not data or not data.data or not data.data.token then
            return false
        end

        if type(success) == 'function' then
            success({ token = data.data.token, key = key }, err)
        end
    end, error)
end

-- url: /files/list
-- method: GET
-- return: object
function StorageFilesApi:List(success, error)
    StorageBaseApi:Post('/files/list', nil, nil, success, error)
end