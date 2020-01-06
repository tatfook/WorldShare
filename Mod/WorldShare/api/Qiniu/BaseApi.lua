--[[
Title: Qiniu Base API
Author(s):  big
Date:  2019.12.16
Place: Foshan
use the lib:
------------------------------------------------------------
local QiniuBaseApi = NPL.load("(gl)Mod/WorldShare/api/Qiniu/BaseApi.lua")
------------------------------------------------------------
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load('../BaseApi.lua')

local QiniuBaseApi = NPL.export()

-- private
function QiniuBaseApi:GetApi()
    return Config.qiniuList[BaseApi:GetEnv()] or ""
end

-- private
function QiniuBaseApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    return headers
end

-- public
function QiniuBaseApi:Get(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Get(url, params, self:GetHeaders(headers), success, error, noTryStatus)
end

-- public
function QiniuBaseApi:Post(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Post(url, params, self:GetHeaders(headers), success, error, noTryStatus)
end

-- public
function QiniuBaseApi:Put(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Put(url, params, self:GetHeaders(headers), success, error, noTryStatus)
end

-- public
function QiniuBaseApi:Delete(url, params, headers, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Delete(url, params, self:GetHeaders(headers), success, error, noTryStatus)
end

-- public
function QiniuBaseApi:PostFields(url, headers, content, success, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:PostFields(url, headers, content, success, error, noTryStatus)
end