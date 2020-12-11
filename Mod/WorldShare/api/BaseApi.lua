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

-- config
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")

-- service
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")

-- libs
local GoogleAnalytics = NPL.load("GoogleAnalytics")

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

function BaseApi:PostFields(...)
    HttpRequest:PostFields(...)
end

function BaseApi:Logger(method, fullUrl, url, error)
    if not self.logger then
        self:LoggerSingletonInit()
    end

    return function(data, err)
        -- send directly
        self.logger:collect(
            "worldshare_api_error",
            "API: " .. method .. " " .. url,
            format("httpstatus: %d, url: %s, content: %s",
                err,
                fullUrl,
                NPL.ToJson(data, true)
            )
        )

        if type(error) == 'function' then
            error(data, err)
        end
    end
end

function BaseApi:LoggerSingletonInit()
    self.logger = GoogleAnalytics.LogCollector:new():init()
end