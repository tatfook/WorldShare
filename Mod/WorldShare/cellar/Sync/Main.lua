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
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local SyncToLocal = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua")
local SyncToDataSource = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToDataSource.lua")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")

local WorldShare = commonlib.gettable("Mod.WorldShare")
local Encoding = commonlib.gettable("commonlib.Encoding")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")

local SyncMain = NPL.export()

function SyncMain:OnWorldLoad()
    function Handle()
        -- 没有登陆则直接使用离线模式
        if (KeepworkService:IsSignedIn()) then
            Compare:Init()
        end
    end

    self:GetCurrentWorldInfo(function()
        CreateWorld:CheckRevision(function()
            Handle()
        end)
    end)
end

function SyncMain:GetCurrentWorldInfo(callback)
    local folderDefauleName = self:GetWorldDefaultName()
    local foldername = {
        default = folderDefauleName,
        utf8 = Encoding.DefaultToUtf8(folderDefauleName),
        base32 = GitEncoding.Base32(Encoding.DefaultToUtf8(folderDefauleName))
    }

    Store:Set("world/foldername", foldername)

    local currentWorld = Store:Get("world/currentWorld")

    if GameLogic.IsReadOnly() then
        local originWorldPath = ParaWorld.GetWorldDirectory()
        local worldTag = WorldCommon.GetWorldInfo() or {}

        Store:Set("world/worldTag", worldTag)
        Store:Set("world/currentWorld", {
            IsFolder = false,
            is_zip = true,
            Title = worldTag.name,
            author = "None",
            costTime = "0:0:0",
            filesize = 0,
            foldername = foldername.utf8,
            grade = "primary",
            icon = "Texture/3DMapSystem/common/page_world.png",
            ip = "127.0.0.1",
            mode = "survival",
            modifyTime = 0,
            nid = "",
            order = 0,
            preview = "",
            progress = "0",
            size = 0,
            worldpath = originWorldPath,
            kpProjectId = worldTag.kpProjectId
        })
    else
        local compareWorldList = Store:Get("world/compareWorldList")

        if compareWorldList then
            local searchCurrentWorld = nil
    
            for key, item in ipairs(compareWorldList) do
                if item.foldername == foldername.utf8 and not item.is_zip then
                    searchCurrentWorld = item
                    break
                end
            end
    
            if (searchCurrentWorld) then
                currentWorld = searchCurrentWorld
    
                local worldTag = LocalService:GetTag(currentWorld.worldpath)
                worldTag.size = filesize
                LocalService:SetTag(format("%s/", currentWorld.worldpath), worldTag)
    
                Store:Set("world/worldTag", worldTag)
                Store:Set("world/currentWorld", currentWorld)
            end
        end
    end

    if not currentWorld then -- new world
        local originWorldPath = ParaWorld.GetWorldDirectory()
        local worldTag = WorldCommon.GetWorldInfo() or {}

        Store:Set("world/worldTag", worldTag)
        Store:Set("world/currentWorld", {
            IsFolder = true,
            is_zip = false,
            Title = worldTag.name,
            author = "None",
            costTime = "0:0:0",
            filesize = 0,
            foldername = foldername.utf8,
            grade = "primary",
            icon = "Texture/3DMapSystem/common/page_world.png",
            ip = "127.0.0.1",
            mode = "survival",
            modifyTime = 0,
            nid = "",
            order = 0,
            preview = "",
            progress = "0",
            size = 0,
            worldpath = originWorldPath, 
            kpProjectId = worldTag.kpProjectId
        })
    end

    if type(callback) == 'function' then
        callback()
    end
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
        Store:remove('page/StartSyncUseLocal')
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
    local currentWorld = Store:Get("world/currentWorld")

    local worldRevision = WorldRevision:new():init(currentWorld and currentWorld.worldpath)
    worldRevision:Backup()
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
    local currentWorld = Store:Get("world/currentWorld")

    return WorldShare:GetWorldData("revision", currentWorld and currentWorld.worldpath .. '/')
end

function SyncMain:CheckWorldSize()
    local currentWorld = Store:Get("world/currentWorld")
    local userType = Store:Get("user/userType")

    if not currentWorld or not currentWorld.worldpath  or #currentWorld.worldpath == 0 then
        return false
    end

    local filesTotal = LocalService:GetWorldSize(currentWorld.worldpath)
    local maxSize = 0

    if (userType == "vip") then
        maxSize = 50 * 1024 * 1024
    else
        maxSize = 25 * 1024 * 1024
    end

    if (filesTotal > maxSize) then
        self:ShowBeyondVolume()

        return true
    else
        return false
    end
end

function SyncMain:GetWorldDateTable()
    local currentWorld = Store:Get("world/currentWorld")
    local date = {}

    if (currentWorld and currentWorld.tooltip) then
        for item in string.gmatch(currentWorld.tooltip, "[^:]+") do
            date[#date + 1] = item
        end

        date = date[1]
    else
        date = os.date("%Y-%m-%d-%H-%M-%S")
    end

    return date
end
