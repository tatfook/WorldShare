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
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local GenerateMdPage = NPL.load("(gl)Mod/WorldShare/cellar/Common/GenerateMdPage.lua")
local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local SyncToLocal = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua")
local SyncToDataSource = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToDataSource.lua")

local WorldShare = commonlib.gettable("Mod.WorldShare")
local Encoding = commonlib.gettable("commonlib.Encoding")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")

local SyncMain = NPL.export()

function SyncMain:SyncWillEnterWorld()
    function Handle()
        -- 没有登陆则直接使用离线模式
        if (KeepworkService:IsSignedIn()) then
            Store:Remove("world/shareMode")
            Compare:Init()
        end
    end

    if (self:IsCommandEnter()) then
        self:CommandEnter(Handle)
    else
        Handle()
    end
end

function SyncMain:SyncWillLeavaWorld()
    Store:Remove("world/enterWorld")
end

function SyncMain:IsCommandEnter()
    local enterWorld = Store:Get("world/enterWorld")

    if (not enterWorld) then
        return true
    else
        return false
    end
end

function SyncMain:CommandEnter(callback)
    Store:Set("world/isCommandEnter", true)
    Store:Set("world/isEnterWorld", true)
    local world = self:GetWorldDefaultName()
    local foldername = {}

    foldername.default = world
    foldername.utf8 = Encoding.DefaultToUtf8(foldername.default)
    foldername.base32 = GitEncoding.Base32(foldername.utf8)

    Store:Set("world/foldername", foldername)
    Store:Set("world/enterFoldername", foldername)

    local function HandleSelectWorld()
        local compareWorldList = Store:Get("world/compareWorldList")

        local currentWorld = nil
        local worldDir = {}

        for key, item in ipairs(compareWorldList) do
            if (item.foldername == foldername.utf8) then
                currentWorld = item
            end
        end

        if (currentWorld) then
            worldDir.default = format("%s/", currentWorld.worldpath)
            worldDir.utf8 = Encoding.DefaultToUtf8(worldDir.default)

            Store:Set("world/worldDir", worldDir)
            Store:Set("world/enterWorldDir", worldDir)

            local worldTag = LocalService:GetTag(foldername.default)

            worldTag.size = filesize
            LocalService:SetTag(worldDir.default, worldTag)
            Store:Set("world/worldTag", worldTag)

            Store:Set("world/selectWorld", currentWorld)
            Store:Set("world/enterWorld", currentWorld)
        end
    end

    WorldList:RefreshCurrentServerList(
        function()
            HandleSelectWorld()

            if type(callback) == "function" then
                callback()
            end
        end,
        true
    )
end

function SyncMain:GetWorldFolder()
    return LocalLoadWorld.GetWorldFolder()
end

function SyncMain:GetWorldFolderFullPath()
    return LocalLoadWorld.GetWorldFolderFullPath()
end

function SyncMain:GetWorldDefaultName()
    local originWorldPath = ParaWorld.GetWorldDirectory()

    world = string.match(originWorldPath, "worlds/DesignHouse/.+")

    if(not world) then
        world = string.match(originWorldPath, "worlds\\DesignHouse\\.+")
    end

    if(not world) then
        return ''
    end

    world = string.gsub(world, "worlds/DesignHouse/", "")
    world = string.gsub(world, "worlds\\DesignHouse\\", "")
    world = string.gsub(world, "/", "")
    world = string.gsub(world, "\\", "")

    return world
end

function SyncMain:ShowStartSyncPage()
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/StartSync.html", "StartSync")

    params._page.OnClose = function()
        Store:Remove('page/StartSync')
    end
end

function SyncMain:SetStartSyncPage()
    Store:Set('page/StartSync', document:GetPageCtrl())
end

function SyncMain:CloseStartSyncPage()
    local StartSyncPage = Store:Get('page/StartSync')

    if (StartSyncPage) then
        StartSyncPage:CloseWindow()
    end
end

function SyncMain:ShowBeyondVolume()
    SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/BeyondVolume.html", "BeyondVolume")
end

function SyncMain:SetBeyondVolumePage()
    Store:Set('page/BeyondVolume', document:GetPageCtrl())
end

function SyncMain:CloseBeyondVolumePage()
    local BeyondVolumePage = Store:Get('page/BeyondVolume')

    if (BeyondVolumePage) then
        BeyondVolumePage:CloseWindow()
    end
end

function SyncMain:ShowStartSyncUseLocalPage()
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/UseLocal.html", "StartSyncUseLocal")

    params._page.OnClose = function()
        Store.remove('page/StartSyncUseLocal')
    end
end

function SyncMain:SetStartSyncUseLocalPage()
    Store:Set('page/StartSyncUseLocal', document.GetPageCtrl())
end

function SyncMain:CloseStartSyncUseLocalPage()
    local StartSyncUseLocalPage = Store:Get('page/StartSyncUseLocal')

    if (StartSyncUseLocalPage) then
        StartSyncUseLocalPage:CloseWindow()
    end
end

function SyncMain:ShowStartSyncUseDataSourcePage()
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/Templates/UseDataSource.html", "StartSyncUseDataSource")

    params._page.OnClose = function()
        Store:Remove('page/StartSyncUseDataSource')
    end
end

function SyncMain:SetStartSyncUseDataSourcePage()
    Store:Set('page/StartSyncUseDataSource', document.GetPageCtrl())
end

function SyncMain:CloseStartSyncUseDataSourcePage()
    local StartSyncUseDataSourcePage = Store:Get('page/StartSyncUseDataSource')

    if (StartSyncUseDataSourcePage) then
        StartSyncUseDataSourcePage:CloseWindow()
    end
end

function SyncMain:ShowDialog(url, name)
    return Utils:ShowWindow(0, 0, url, name, 0, 0, "_fi", false)
end

function SyncMain:BackupWorld()
    local worldDir = Store:Get("world/worldDir")

    local world_revision = WorldRevision:new():init(worldDir.default)
    world_revision:Backup()
end

function SyncMain:SyncToLocal()
    if (self:CheckWorldSize()) then
        return false
    end

    SyncToLocal:Init()
end

function SyncMain:SyncToDataSource()
    if (self:CheckWorldSize()) then
        return false
    end

    SyncToDataSource:Init()
end

function SyncMain.GetCurrentRevision()
    return tonumber(Store:Get("world/currentRevision")) or 0
end

function SyncMain.GetRemoteRevision()
    return tonumber(Store:Get("world/remoteRevision")) or 0
end

function SyncMain:GetCurrentRevisionInfo()
    local worldDir = Store:Get("world/worldDir")

    return WorldShare:GetWorldData("revision", worldDir.default)
end

function SyncMain:CheckWorldSize()
    local worldDir = Store:Get("world/worldDir")
    local userType = Store:Get("user/userType")

    local filesTotal = LocalService:GetWorldSize(worldDir.default)
    local maxSize = 0

    if (userType == "vip") then
        maxSize = 50 * 1024 * 1024
    else
        maxSize = 25 * 1024 * 1024
    end

    if (filesTotal > maxSize) then
        SyncMain:showBeyondVolume()

        return true
    else
        return false
    end
end

function SyncMain:GetWorldDateTable()
    local selectWorld = Store:Get("world/selectWorld")
    local date = {}

    if (selectWorld and selectWorld.tooltip) then
        for item in string.gmatch(selectWorld.tooltip, "[^:]+") do
            date[#date + 1] = item
        end

        date = date[1]
    else
        date = os.date("%Y-%m-%d-%H-%M-%S")
    end

    return date
end