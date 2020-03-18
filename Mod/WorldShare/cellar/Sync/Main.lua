--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
------------------------------------------------------------
]]
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local SyncToLocal = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua")
local SyncToDataSource = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToDataSource.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local WorldShare = commonlib.gettable("Mod.WorldShare")
local Encoding = commonlib.gettable("commonlib.Encoding")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")

local SyncMain = NPL.export()

function SyncMain:OnWorldLoad()
    Compare:GetCurrentWorldInfo(function()
        CreateWorld:CheckRevision()
    end)
end

function SyncMain:ShowStartSyncPage(useOffline)
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/StartSync.html?useOffline=" .. (useOffline and "true" or "false"), "StartSync")

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/StartSync')
    end
end

function SyncMain:SetStartSyncPage()
    Mod.WorldShare.Store:Set('page/StartSync', document:GetPageCtrl())
end

function SyncMain:CloseStartSyncPage()
    local StartSyncPage = Mod.WorldShare.Store:Get('page/StartSync')

    if StartSyncPage then
        StartSyncPage:CloseWindow()
    end
end

function SyncMain:ShowBeyondVolume()
    SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/BeyondVolume.html", "BeyondVolume")
end

function SyncMain:SetBeyondVolumePage()
    Mod.WorldShare.Store:Set('page/BeyondVolume', document:GetPageCtrl())
end

function SyncMain:CloseBeyondVolumePage()
    local BeyondVolumePage = Mod.WorldShare.Store:Get('page/BeyondVolume')

    if (BeyondVolumePage) then
        BeyondVolumePage:CloseWindow()
    end
end

function SyncMain:ShowStartSyncUseLocalPage()
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/UseLocal.html", "StartSyncUseLocal")

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/StartSyncUseLocal')
    end
end

function SyncMain:SetStartSyncUseLocalPage()
    Mod.WorldShare.Store:Set('page/StartSyncUseLocal', document.GetPageCtrl())
end

function SyncMain:CloseStartSyncUseLocalPage()
    local StartSyncUseLocalPage = Mod.WorldShare.Store:Get('page/StartSyncUseLocal')

    if StartSyncUseLocalPage then
        StartSyncUseLocalPage:CloseWindow()
    end
end

function SyncMain:ShowStartSyncUseDataSourcePage()
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/UseDataSource.html", "StartSyncUseDataSource")

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/StartSyncUseDataSource')
    end
end

function SyncMain:SetStartSyncUseDataSourcePage()
    Mod.WorldShare.Store:Set('page/StartSyncUseDataSource', document.GetPageCtrl())
end

function SyncMain:CloseStartSyncUseDataSourcePage()
    local StartSyncUseDataSourcePage = Mod.WorldShare.Store:Get('page/StartSyncUseDataSource')

    if (StartSyncUseDataSourcePage) then
        StartSyncUseDataSourcePage:CloseWindow()
    end
end

function SyncMain:ShowDialog(url, name)
    return Mod.WorldShare.Utils.ShowWindow(0, 0, url, name, 0, 0, "_fi", false)
end

function SyncMain:BackupWorld()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    local revision = WorldRevision:new():init(currentWorld and currentWorld.worldpath)
    revision:Checkout()
    revision:Backup()
end

function SyncMain:SyncToLocal(callback)
    if self:CheckWorldSize() then
        return false
    end

    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld.kpProjectId then
        return false
    end

    -- get latest commidId
    KeepworkServiceProject:GetProject(
        currentWorld.kpProjectId,
        function(data, err)
            if data and data.world and data.world.commitId then
                currentWorld.lastCommitId = data.world.commitId
            end

            Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)

            SyncToLocal:Init(function(result, msg)
                if result == false then
                    if msg == 'NEWWORLD' then
                        UserConsole:ClosePage()
                        GameLogic.AddBBS(nil, L"服务器未找到世界数据，请新建", 3000, "255 255 0")
                        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                        CreateWorld:CreateNewWorld(currentWorld.foldername)
                        return false
                    end
        
                    GameLogic.AddBBS(nil, msg, 3000, "255 0 0")
                end
        
                if type(callback) == 'function' then
                    callback(result, msg)
                end
        
                WorldList:RefreshCurrentServerList()
            end)
        end,
        function()
            GameLogic.AddBBS(nil, L"获取项目信息失败", 3000, "255 0 0")
        end
    )
end

function SyncMain:SyncToDataSource(callback)
    if self:CheckWorldSize() then
        return false
    end

    -- close the notice
    Mod.WorldShare.MsgBox:Close()

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld.worldpath or currentWorld.worldpath == "" then
        return false
    end

    SyncToDataSource:Init(function(result, msg)
        if result == false then
            if msg == 'RE-ENTRY' then
                GameLogic.AddBBS(nil, L"请重新登录", 3000, "255 0 0")

                LoginModal:Init(function()
                    Mod.WorldShare.Utils.SetTimeOut(function()
                        self:SyncToDataSource(callback)
                    end, 300)
                end)

                return false
            end

            GameLogic.AddBBS(nil, msg, 3000, "255 0 0")
        end

        if type(callback) == 'function' then
            callback(result, msg)
        end

        WorldList:RefreshCurrentServerList()
    end)
end

function SyncMain:CheckTagName(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if currentWorld and currentWorld.remote_tagname and currentWorld.worldpath then
        if currentWorld.remote_tagname ~= currentWorld.local_tagname then
            local params = Mod.WorldShare.Utils.ShowWindow(
                500,
                190,
                "Mod/WorldShare/cellar/Sync/Templates/CheckTagName.html?remote_tagname=" .. currentWorld.remote_tagname .. "&local_tagname=" .. currentWorld.local_tagname,
                "CheckTagName"
            )
            params._page.callback = function(params)
                if params ~= 'local' and params ~= 'remote' then
                    return false
                end

                if params == 'remote' then
                    local saveWorldHandler = SaveWorldHandler:new():Init(currentWorld.worldpath)
                    local taginfo = saveWorldHandler:LoadWorldInfo()

                    taginfo.name = currentWorld.remote_tagname
                    saveWorldHandler:SaveWorldInfo(taginfo)

                    currentWorld.local_tagname = currentWorld.remote_tagname
                    Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
                end

                if type(callback) == 'function' then
                    callback()
                end
            end

            return false
        end
    end

    if type(callback) == 'function' then
        callback()
    end
end

function SyncMain.GetCurrentRevision()
    return tonumber(Mod.WorldShare.Store:Get("world/currentRevision")) or 0
end

function SyncMain.GetRemoteRevision()
    return tonumber(Mod.WorldShare.Store:Get("world/remoteRevision")) or 0
end

function SyncMain:GetCurrentRevisionInfo()
    WorldShare.worldData = nil
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    return WorldShare:GetWorldData("revision", currentWorld and currentWorld.worldpath .. '/')
end

function SyncMain:CheckWorldSize()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")
    local userType = Mod.WorldShare.Store:Get("user/userType")

    if not currentWorld or not currentWorld.worldpath  or #currentWorld.worldpath == 0 then
        return false
    end

    local filesTotal = LocalService:GetWorldSize(currentWorld.worldpath)
    local maxSize = 0

    if userType == "vip" then
        maxSize = 50 * 1024 * 1024
    else
        maxSize = 25 * 1024 * 1024
    end

    if filesTotal > maxSize then
        self:ShowBeyondVolume()

        return true
    else
        return false
    end
end

function SyncMain:GetWorldDateTable()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")
    local date = {}

    if currentWorld and currentWorld.tooltip then
        for item in string.gmatch(currentWorld.tooltip, "[^:]+") do
            date[#date + 1] = item
        end

        date = date[1]
    else
        date = os.date("%Y-%m-%d-%H-%M-%S")
    end

    return date
end
