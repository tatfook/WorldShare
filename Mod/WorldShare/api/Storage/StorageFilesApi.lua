--[[
Title: Storage Files API
Author(s): big
CreateDate: 2019.12.16
ModifyDate: 2022.7.11
Place: Foshan
use the lib:
------------------------------------------------------------
local StorageFilesApi = NPL.load('(gl)Mod/WorldShare/api/Storage/StorageFilesApi.lua')
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
-- method: POST
-- params: key string
-- return: object
function StorageFilesApi:List(key, success, error)
    local params = {}

    if key and type(key) == 'string' then
        params.key = key
    end

    StorageBaseApi:Post('/files/list', params, nil, success, error)
end