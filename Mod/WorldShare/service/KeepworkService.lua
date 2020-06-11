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
local GitService = NPL.load("./GitService.lua")
local GitGatewayService = NPL.load("./GitGatewayService.lua")
local LocalService = NPL.load("./LocalService.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local KeepworkServiceProject = NPL.load('./KeepworkService/Project.lua')
local KeepworkServiceSession = NPL.load('./KeepworkService/Session.lua')
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
    return KeepworkServiceSession:IsSignedIn()
end

function KeepworkService:GetToken()
    local token = Mod.WorldShare.Store:Get('user/token')

    return token or ''
end

-- get keepwork project url
function KeepworkService:GetShareUrl()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId then
        return ''
    end

    return format("%s/pbl/project/%d/", self:GetKeepworkUrl(), currentWorld.kpProjectId)
end

function KeepworkService:SetCurrentCommitId()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.worldpath or
       not currentWorld.lastCommitId then
        return false
    end

    if currentWorld.worldpath == "" then
        -- first download world
        currentWorld.worldpath = Mod.WorldShare.Utils.GetWorldFolderFullPath() .. "/" .. commonlib.Encoding.Utf8ToDefault(currentWorld.foldername) .. "/"
        Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
    end

    Mod.WorldShare.worldData = nil
    Mod.WorldShare:SetWorldData("revision", { id = currentWorld.lastCommitId }, currentWorld.worldpath)
    Mod.WorldShare:SetWorldData("username", currentWorld.user and currentWorld.user.username or "", currentWorld.worldpath)
    Mod.WorldShare:SaveWorldData(currentWorld.worldpath)
end