--[[
Title: Base API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local BaseApi = NPL.load("(gl)Mod/WorldShare/api/BaseApi.lua")
------------------------------------------------------------
The class just provider for api class
]]

local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")

local BaseApi = NPL.export()

function BaseApi:GetEnv()
    for key, item in pairs(Config.env) do
        if key == Config.defaultEnv then
            return Config.defaultEnv
        end
    end

	return Config.env.ONLINE
end

function BaseApi:Get(...)
    HttpRequest:Get(...)
end

function BaseApi:Post(...)
    HttpRequest:Post(...)
end

function BaseApi:Put(...)
    HttpRequest:Put(...)
end

function BaseApi:Delete(...)
    HttpRequest:Delete(...)
end

