--[[
Title: KeepworkService
Author(s):  big
Date:  2018.06.21
Place: Foshan
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkService = commonlib.gettable("Mod.WorldShare.service.KeepworkService")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginUserInfo.lua")

local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")

local KeepworkService = commonlib.gettable("Mod.WorldShare.service.KeepworkService")

function getApi(url)
    return format("%s%s", LoginUserInfo.site, url)
end

function getHeader()
    return { Authorization = format("Bearer %s", LoginUserInfo.token) }
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