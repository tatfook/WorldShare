--[[
Title: Storage Base API
Author(s):  big
Date:  2019.12.16
Place: Foshan
use the lib:
------------------------------------------------------------
local StorageBaseApi = NPL.load("(gl)Mod/WorldShare/api/Storage/BaseApi.lua")
------------------------------------------------------------
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load('../BaseApi.lua')

local StorageBaseApi = NPL.export()

-- private
function StorageBaseApi:GetApi()
    return Config.storageList[BaseApi:GetEnv()] or ""
end

-- private
function StorageBaseApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    local token = Mod.WorldShare.Store:Get("user/token")

    if token and not headers.notTokenRequest and not headers["Authorization"] then
        headers["Authorization"] = format("Bearer %s", token)
    end

    headers.notTokenRequest = nil

    return headers
end

-- public
function StorageBaseApi:Get(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Get(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function StorageBaseApi:Post(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Post(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function StorageBaseApi:Put(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Put(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function StorageBaseApi:Delete(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Delete(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end
