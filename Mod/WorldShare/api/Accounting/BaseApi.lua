--[[
Title: Accounting Base API
Author(s):  big
Date:  2020.9.27
Place: Foshan
use the lib:
------------------------------------------------------------
local AccountingBaseApi = NPL.load("(gl)Mod/WorldShare/api/Accounting/BaseApi.lua")
------------------------------------------------------------
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load('../BaseApi.lua')

local AccountingBaseApi = NPL.export()

-- private
function AccountingBaseApi:GetApi()
    return Config.accountingList[BaseApi:GetEnv()] or ""
end

-- private
function AccountingBaseApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    local token = Mod.WorldShare.Store:Get("user/token")

    if token and not headers.notTokenRequest and not headers["Authorization"] then
        headers["Authorization"] = format("Bearer %s", token)
    end

    headers.notTokenRequest = nil

    return headers
end

-- public
function AccountingBaseApi:Get(url, params, headers, callback, error, noTryStatus, timeout)
    url = self:GetApi() .. url

    BaseApi:Get(url, params, self:GetHeaders(headers), callback, error, noTryStatus, timeout)
end

-- public
function AccountingBaseApi:Post(url, params, headers, callback, error, noTryStatus, timeout)
    url = self:GetApi() .. url

    BaseApi:Post(url, params, self:GetHeaders(headers), callback, error, noTryStatus, timeout)
end

-- public
function AccountingBaseApi:Put(url, params, headers, callback, error, noTryStatus, timeout)
    url = self:GetApi() .. url

    BaseApi:Put(url, params, self:GetHeaders(headers), callback, error, noTryStatus, timeout)
end

-- public
function AccountingBaseApi:Delete(url, params, headers, callback, error, noTryStatus, timeout)
    url = self:GetApi() .. url

    BaseApi:Delete(url, params, self:GetHeaders(headers), callback, error, noTryStatus, timeout)
end
