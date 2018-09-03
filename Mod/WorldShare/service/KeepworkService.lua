--[[
Title: KeepworkService
Author(s):  big
Date:  2018.06.21
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
------------------------------------------------------------
]]
local LoginUserInfo = NPL.load('(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua')
local HttpRequest = NPL.load('./HttpRequest.lua')
local Store = NPL.load('(gl)Mod/WorldShare/store/Store.lua')

local KeepworkService = NPL.export()

function getApi(url)
    return format("%s%s", LoginUserInfo.site(), url)
end

function getHeader()
    local token = Store:get('user/token')

    return { Authorization = format("Bearer %s", token) }
end

function getParams(url, method, params, callback)
    local params = {
        method = method or 'GET',
        url = getApi(url),
        json = true,
        headers = getHeader(),
        form = params
    }

    HttpRequest:GetUrl(params, callback)
end

function KeepworkService.getWorldsList(callback)
    if (not LoginUserInfo.IsSignedIn()) then
        return false
    end

    local params = {amount = 100}
    getParams("/api/mod/worldshare/models/worlds", nil, params, callback)
end

function KeepworkService.deleteWorld(foldername, callback)
    if (not LoginUserInfo.IsSignedIn()) then
        return false
    end

    local params = {
        worldsName = foldername
    }

    getParams("/api/mod/worldshare/models/worlds", 'DELETE', params, callback)
end

function KeepworkService:RefreshKeepworkList(worldInfo, callback)
    if (not LoginUserInfo.IsSignedIn()) then
        return false
    end

    getParams("/api/mod/worldshare/models/worlds/refresh", 'POST', worldInfo, callback)
end