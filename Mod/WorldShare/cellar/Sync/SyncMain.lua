--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
------------------------------------------------------------
]]
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local SyncCompare = NPL.load("./SyncCompare.lua")
local SyncToLocal = NPL.load("./SyncToLocal.lua")
local SyncToDataSource = NPL.load("./SyncToDataSource.lua")
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local LoginWorldList = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginWorldList.lua")
local GenerateMdPage = NPL.load("(gl)Mod/WorldShare/cellar/Common/GenerateMdPage.lua")
local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

local WorldShare = commonlib.gettable("Mod.WorldShare")
local Encoding = commonlib.gettable("commonlib.Encoding")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")

local SyncMain = NPL.export()

function SyncMain:SyncWillEnterWorld()
    function compare()
        -- 没有登陆则直接使用离线模式
        if (LoginUserInfo.IsSignedIn()) then
            Store:remove("world/ShareMode")
            SyncCompare:syncCompare()
        end
    end

    if (self:isCommandEnter()) then
        self:CommandEnter(compare)
    else
        compare()
    end
end

function SyncMain:SyncWillLeavaWorld()
    Store:remove("world/enterWorld")
end

function SyncMain:isCommandEnter()
    local enterWorld = Store:get("world/enterWorld")

    if (not enterWorld) then
        return true
    else
        return false
    end
end

function SyncMain:CommandEnter(callback)
    Store:set("world/IsEnterWorld", true)
    local world = self:GetWorldDefaultName()
    local foldername = {}

    foldername.default = world
    foldername.utf8 = Encoding.DefaultToUtf8(foldername.default)
    foldername.base32 = GitEncoding.base32(foldername.utf8)

    Store:set("world/foldername", foldername)
    Store:set("world/enterFoldername", foldername)

    local function handleSelectWorld()
        local compareWorldList = Store:get("world/compareWorldList")

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

            Store:set("world/worldDir", worldDir)
            Store:set("world/enterWorldDir", worldDir)

            local worldTag = LocalService:GetTag(foldername.default)

            worldTag.size = filesize
            LocalService:SetTag(worldDir.default, worldTag)
            Store:set("world/worldTag", worldTag)

            Store:set("world/selectWorld", currentWorld)
            Store:set("world/enterWorld", currentWorld)
        end
    end

    LoginWorldList.RefreshCurrentServerList(
        function()
            handleSelectWorld()

            if (type(callback) == "function") then
                callback()
            end
        end
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
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/StartSync.html", "StartSync")

    params._page.OnClose = function()
        Store:remove('page/StartSync')
    end
end

function SyncMain:setStartSyncPage()
    Store:set('page/StartSync', document:GetPageCtrl())
end

function SyncMain:closeStartSyncPage()
    local StartSyncPage = Store:get('page/StartSync')

    if (StartSyncPage) then
        StartSyncPage:CloseWindow()
    end
end

function SyncMain:ShowBeyondVolume()
    SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/BeyondVolume.html", "BeyondVolume")
end

function SyncMain:setBeyondVolumePage()
    Store:set('page/BeyondVolume', document:GetPageCtrl())
end

function SyncMain:closeBeyondVolumePage()
    local BeyondVolumePage = Store:get('page/BeyondVolume')

    if (BeyondVolumePage) then
        BeyondVolumePage:CloseWindow()
    end
end

function SyncMain:ShowStartSyncUseLocalPage()
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/StartSyncUseLocal.html", "StartSyncUseLocal")

    params._page.OnClose = function()
        Store.remove('page/StartSyncUseLocal')
    end
end

function SyncMain:setStartSyncUseLocalPage()
    Store:set('page/StartSyncUseLocal', document.GetPageCtrl())
end

function SyncMain:closeStartSyncUseLocalPage()
    local StartSyncUseLocalPage = Store:get('page/StartSyncUseLocal')

    if (StartSyncUseLocalPage) then
        StartSyncUseLocalPage:CloseWindow()
    end
end

function SyncMain:ShowStartSyncUseDataSourcePage()
    local params = SyncMain:ShowDialog("Mod/WorldShare/cellar/Sync/StartSyncUseDataSource.html", "StartSyncUseDataSource")

    params._page.OnClose = function()
        Store:remove('page/StartSyncUseDataSource')
    end
end

function SyncMain:setStartSyncUseDataSourcePage()
    Store:set('page/StartSyncUseDataSource', document.GetPageCtrl())
end

function SyncMain:closeStartSyncUseDataSourcePage()
    local StartSyncUseDataSourcePage = Store:get('page/StartSyncUseDataSource')

    if (StartSyncUseDataSourcePage) then
        StartSyncUseDataSourcePage:CloseWindow()
    end
end

function SyncMain:ShowDialog(url, name)
    return Utils:ShowWindow(0, 0, url, name, 0, 0, "_fi", false)
end

function SyncMain:backupWorld()
    local worldDir = Store:get("world/worldDir")

    local world_revision = WorldRevision:new():init(worldDir.default)
    world_revision:Backup()
end

function SyncMain:syncToLocal()
    SyncToLocal:init()
end

function SyncMain:syncToDataSource()
    SyncToDataSource:init()
end

function SyncMain.GetCurrentRevision()
    return tonumber(Store:get("world/currentRevision")) or 0
end

function SyncMain.GetRemoteRevision()
    return tonumber(Store:get("world/remoteRevision")) or 0
end

function SyncMain:RefreshKeepworkList(callback)
    local foldername = Store:get("world/foldername")
    local projectId

    local function handleKeepworkList(data, err)
        if (not data or not data[1]) then
            _guihelper.MessageBox(L"获取Commit列表失败")
            return false
        end

        local lastCommits = data[1]
        local lastCommitFile = lastCommits.title:gsub("keepwork commit: ", "")
        local lastCommitSha = lastCommits.id

        if (lastCommitFile ~= "revision.xml") then
            _guihelper.MessageBox(L"上一次同步到数据源同步失败，请重新同步世界到数据源")
            return false
        end

        local worldDir = Store:get("world/worldDir")
        local selectWorld = Store:get("world/selectWorld")
        local worldTag = Store:get("world/worldTag")
        local dataSourceInfo = Store:get("user/dataSourceInfo")
        local localFiles = LocalService:LoadFiles(worldDir.default)

        self:SetCurrentCommidId(lastCommitSha)

        Store:set("world/localFiles", localFiles)

        local readme = ""
        for key, value in ipairs(localFiles) do
            if (value.filename == "README.md") then
                readme = value.file_content_t
            end
        end

        local preview =
            format(
            "%s/%s/%s/raw/master/preview.jpg",
            dataSourceInfo.rawBaseUrl,
            dataSourceInfo.dataSourceUsername,
            foldername.base32
        )

        local filesTotals = selectWorld and selectWorld.size or 0

        local worldInfo = {}

        worldInfo.modDate = SyncMain:GetWorldDateTable()
        worldInfo.worldsName = foldername.utf8
        worldInfo.revision = Store:get("world/currentRevision")
        worldInfo.dataSourceType = dataSourceInfo.dataSourceType
        worldInfo.gitlabProjectId = projectId
        worldInfo.readme = readme
        worldInfo.preview = preview
        worldInfo.filesTotals = filesTotals
        worldInfo.commitId = lastCommitSha
        worldInfo.name = worldTag.name
        worldInfo.download =
            format(
            "%s/%s/%s/repository/archive.zip?ref=%s",
            dataSourceInfo.rawBaseUrl,
            dataSourceInfo.dataSourceUsername,
            foldername.base32,
            worldInfo.commitId
        )

        LoginMain.setLoginMainPageRefreshing(true)

        GenerateMdPage:genWorldMD(
            worldInfo,
            function()
                KeepworkService:RefreshKeepworkList(
                    worldInfo,
                    function(data, err)
                        if (err ~= 200 or type(data) ~= "table" or data.error.id ~= 0) then
                            _guihelper.MessageBox(L"更新服务器列表失败")
                            return false
                        end

                        worldInfo.opusId = data.data.opusId
                        GenerateMdPage:genWorldMD(worldInfo, callback)
                    end
                )
            end
        )
    end

    GitService:getProjectIdByName(
        foldername.base32,
        function(projectId)
            if(not projectId) then
                return false
            end

            GitService:getCommits(projectId, foldername.base32, false, handleKeepworkList)
        end
    )
end

function SyncMain:SetCurrentCommidId(commitId)
    local worldDir = Store:get("world/worldDir")

    WorldShare:SetWorldData("revision", {id = commitId}, worldDir.default)

    ParaIO.CreateDirectory(format("%smod/", worldDir.default))
    WorldShare:SaveWorldData(worldDir.default)
end

function SyncMain:GetCurrentRevisionInfo()
    local worldDir = Store:get("world/worldDir")

    return WorldShare:GetWorldData("revision", worldDir.default)
end

function SyncMain:checkWorldSize()
    local worldDir = Store:get("world/worldDir")
    local userType = Store:get("user/userType")

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
    local selectWorld = Store:get("world/selectWorld")
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