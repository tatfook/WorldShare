--[[
Title: Keepwork Base API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkBaseApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua")
------------------------------------------------------------
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load('../BaseApi.lua')

local KeepworkBaseApi = NPL.export()

-- private
function KeepworkBaseApi:GetApi()
    return Config.keepworkServerList[BaseApi:GetEnv()] or ""
end

-- private
function KeepworkBaseApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    local token = Mod.WorldShare.Store:Get("user/token")

    if not headers.notTokenRequest and token and not headers["Authorization"] then
        headers["Authorization"] = format("Bearer %s", token)
    end

    headers.notTokenRequest = nil

    return headers
end

-- public
function KeepworkBaseApi:Get(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Get(url, params, self:GetHeaders(headers), success, self:ErrorCollect("GET", url, error), noTryStatus)
end

-- public
function KeepworkBaseApi:Post(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Post(url, params, self:GetHeaders(headers), success, self:ErrorCollect("Post", url, error), noTryStatus)
end

-- public
function KeepworkBaseApi:Put(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Put(url, params, self:GetHeaders(headers), success, self:ErrorCollect("Put", url, error), noTryStatus)
end

-- public
function KeepworkBaseApi:Delete(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Delete(url, params, self:GetHeaders(headers), success, self:ErrorCollect("Delete", url, error), noTryStatus)
end

-- public
function KeepworkBaseApi:ErrorCollect(method, url, error)
    local GoogleAnalytics = NPL.load("GoogleAnalytics")
    local Logger = GoogleAnalytics.LogCollector:new():init()

    return function(data, err)
        -- send directly
        Logger:collect("worldshare_api_error", method, format("httpstatus: %d, url: %s, content: %s", err, url, NPL.ToJson(data, true)))

        if type(error) == 'function' then
            error(data, err)
        end
    end
end
