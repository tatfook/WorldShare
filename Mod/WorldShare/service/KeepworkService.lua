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
local Encoding = commonlib.gettable("commonlib.Encoding")

local GitService = NPL.load("./GitService.lua")
local GitGatewayService = NPL.load("./GitGatewayService.lua")
local LocalService = NPL.load("./LocalService.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local KeepworkServiceProject = NPL.load('./KeepworkService/Project.lua')
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")

local KeepworkService = NPL.export()

function KeepworkService:GetEnv()
    for key, item in pairs(Config.env) do
        if key == Config.defaultEnv then
            return Config.defaultEnv
        end
    end

	return Config.env.ONLINE
end

function KeepworkService:GetKeepworkUrl()
	local env = self:GetEnv()

	return Config.keepworkList[env]
end

function KeepworkService:GetCoreApi()
    local env = self:GetEnv()

    return Config.keepworkServerList[env]
end

function KeepworkService:GetLessonApi()
    local env = self:GetEnv()

    return Config.lessonList[env]
end

function KeepworkService:GetServerList()
    if (LOG.level == "debug") then
        return {
            {value = Config.env.ONLINE, name = Config.env.ONLINE, text = L"使用KEEPWORK登录", selected = true},
            {value = Config.env.STAGE, name = Config.env.STAGE, text = L"使用STAGE登录"},
            {value = Config.env.RELEASE, name = Config.env.RELEASE, text = L"使用RELEASE登录"},
            {value = Config.env.LOCAL, name = Config.env.LOCAL, text = L"使用本地服务登录"}
        }
    else
        return {
            {value = Config.env.ONLINE, name = Config.env.ONLINE, text = L"使用KEEPWORK登录", selected = true}
        }
    end
end

function KeepworkService:IsSignedIn()
    local token = Mod.WorldShare.Store:Get("user/token")

    return token ~= nil
end

function KeepworkService:GetToken()
    local token = Mod.WorldShare.Store:Get('user/token')

    return token or ''
end

-- get keepwork project url
function KeepworkService:GetShareUrl()
    local env = self:GetEnv()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId then
        return ''
    end

    local baseUrl = Config.keepworkList[env]
    local username = Mod.WorldShare.Store:Get("user/username")

    return format("%s/pbl/project/%d/", baseUrl, currentWorld.kpProjectId)
end

function KeepworkService:SetCurrentCommitId()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.worldpath or
       not currentWorld.lastCommitId then
        return false
    end

    Mod.WorldShare.worldData = nil
    Mod.WorldShare:SetWorldData("revision", { id = currentWorld.lastCommitId }, currentWorld.worldpath)
    Mod.WorldShare:SaveWorldData(currentWorld.worldpath)
end