--[[
Title: Es Base API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local EsBaseApi = NPL.load("(gl)Mod/WorldShare/api/Es/BaseApi.lua")
------------------------------------------------------------
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load('../BaseApi.lua')

local EsBaseApi = NPL.export()

-- private
function EsBaseApi:GetApi()
    return Config.esGatewayList[BaseApi:GetEnv()] or ""
end

-- private
function EsBaseApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    local token = Mod.WorldShare.Store:Get("user/token")

    if token and not headers.notTokenRequest and not headers["Authorization"] then
        headers["Authorization"] = format("Bearer %s", token)
    end

    headers.notTokenRequest = nil

    return headers
end

-- public
function EsBaseApi:Get(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Get(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function EsBaseApi:Post(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Post(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function EsBaseApi:Put(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Put(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function EsBaseApi:Delete(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Delete(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end
