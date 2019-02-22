--[[
Title: KeepworkEsService
Author(s):  big
Date:  2019.02.21
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkEsService = NPL.load("(gl)Mod/WorldShare/service/KeepworkEsService.lua")
------------------------------------------------------------
]]
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")
local HttpRequest = NPL.load("./HttpRequest.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local KeepworkEsService = NPL.export()

function KeepworkEsService:GetEnv()
    local env = Store:Get("user/env")

    if not env then
        env = Config.defaultEnv
    end

    return env
end

function KeepworkEsService:GetApi(url)
    if type(url) ~= "string" then
        return ""
    end

    local env = self:GetEnv()

    if not env or not Config.esGatewayList[env] then
        return ""
    end

    return format("%s%s", Config.esGatewayList[env], url)
end

function KeepworkEsService:Request(url, method, params, headers, callback, noTryStatus)
    local params = {
        method = method or "GET",
        url = self:GetApi(url),
        json = true,
        headers = headers or {},
        form = params or {}
    }

    HttpRequest:GetUrl(params, callback, noTryStatus)
end

function KeepworkEsService:GetHeaders(selfDefined, notTokenRequest)
    local headers = {}

    if type(selfDefined) == "table" then
        headers = selfDefined
    end

    local token = Store:Get("user/token")

    if (token and not notTokenRequest and not headers["Authorization"]) then
        headers["Authorization"] = format("Bearer %s", token)
    end

    return headers
end