--[[
Title: Lesson Base API
Author(s):  big
Date:  2019.12.6
Place: Foshan
use the lib:
------------------------------------------------------------
local LessonBaseApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/BaseApi.lua")
------------------------------------------------------------
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load('../BaseApi.lua')

local LessonBaseApi = NPL.export()

-- private
function LessonBaseApi:GetApi()
    return Config.lessonList[BaseApi:GetEnv()] or ""
end

-- private
function LessonBaseApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    local token = Mod.WorldShare.Store:Get("user/token")

    if token and not headers.notTokenRequest and not headers["Authorization"] then
        headers["Authorization"] = format("Bearer %s", token)
    end

    headers.notTokenRequest = nil

    return headers
end

-- public
function LessonBaseApi:Get(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Get(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function LessonBaseApi:Post(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Post(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function LessonBaseApi:Put(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Put(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function LessonBaseApi:Delete(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Delete(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end
