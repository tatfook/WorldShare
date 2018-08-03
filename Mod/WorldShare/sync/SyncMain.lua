--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
local SyncMain  = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
NPL.load("(gl)Mod/WorldShare/main.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncToDataSource.lua")
NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
NPL.load("(gl)Mod/WorldShare/sync/GenerateMdPage.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginUserInfo.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncToLocal.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")

local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local Encoding = commonlib.gettable("commonlib.Encoding")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local SyncToLocal = commonlib.gettable("Mod.WorldShare.sync.SyncToLocal")
local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource")
local KeepworkService = commonlib.gettable("Mod.WorldShare.service.KeepworkService")
local GenerateMdPage = commonlib.gettable("Mod.WorldShare.sync.GenerateMdPage")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")
local WorldShare = commonlib.gettable("Mod.WorldShare")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")

SyncMain.SyncPage = nil
SyncMain.BeyondPage = nil

function SyncMain:ctor()
end

function SyncMain:init()
end

function SyncMain:SyncWillEnterWorld()
    -- 没有登陆则直接使用离线模式
    local enterWorld = GlobalStore.get("enterWorld")

    function compare()
        if (LoginUserInfo.IsSignedIn()) then
            GlobalStore.remove("ShareMode")
            SyncCompare:syncCompare()
        end
    end

    if (not enterWorld) then
        self:CommandEnter(compare)
    else
        compare()
    end
end

function SyncMain:SyncWillLeavaWorld()
    GlobalStore.remove("enterWorld")
end

function SyncMain:CommandEnter(callback)
    GlobalStore.set("IsEnterWorld", true)
    local world = self:GetWorldDefaultName()
    local foldername = {}

    foldername.default = world
    foldername.utf8 = Encoding.DefaultToUtf8(foldername.default)
    foldername.base32 = GitEncoding.base32(foldername.utf8)

    GlobalStore.set("foldername", foldername)
    GlobalStore.set("enterFoldername", foldername)

    local function handleSelectWorld()
        local compareWorldList = GlobalStore.get("compareWorldList")

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

            GlobalStore.set("worldDir", worldDir)
            GlobalStore.set("enterWorldDir", worldDir)

            local worldTag = LocalService:GetTag(foldername.default)

            worldTag.size = filesize
            LocalService:SetTag(worldDir.default, worldTag)
            GlobalStore.set("worldTag", worldTag)

            GlobalStore.set("selectWorld", currentWorld)
            GlobalStore.set("enterWorld", currentWorld)
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

    world = string.gsub(world, "worlds/DesignHouse/", "")
    world = string.gsub(world, "worlds\\DesignHouse\\", "")
    world = string.gsub(world, "/", "")
    world = string.gsub(world, "\\", "")

    return world
end

function SyncMain.setSyncPage()
    SyncMain.SyncPage = document:GetPageCtrl()
end

function SyncMain.setBeyondPage()
    SyncMain.BeyondPage = document:GetPageCtrl()
end

function SyncMain.closeSyncPage()
    if (SyncMain.SyncPage) then
        SyncMain.SyncPage:CloseWindow()
    end
end

function SyncMain.closeBeyondPage()
    SyncMain.BeyondPage:CloseWindow()
end

function SyncMain:StartSyncPage()
    SyncMain:ShowDialog("Mod/WorldShare/sync/StartSync.html", "StartSync")
end

function SyncMain:useLocalGUI()
    SyncMain:ShowDialog("Mod/WorldShare/sync/StartSyncUseLocal.html", "StartSyncUseLocal")
end

function SyncMain:useDataSourceGUI()
    SyncMain:ShowDialog("Mod/WorldShare/sync/StartSyncUseDataSource.html", "StartSyncUseDataSource")
end

function SyncMain:showBeyondVolume()
    SyncMain:ShowDialog("Mod/WorldShare/sync/BeyondVolume.html", "BeyondVolume")
end

function SyncMain:ShowDialog(url, name)
    Utils:ShowWindow(0, 0, url, name, 0, 0, "_fi", false)
end

function SyncMain:backupWorld()
    local worldDir = GlobalStore.get("worldDir")

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
    return tonumber(GlobalStore.get("currentRevision"))
end

function SyncMain.GetRemoteRevision()
    return tonumber(GlobalStore.get("remoteRevision"))
end

function SyncMain:RefreshKeepworkList(callback)
    local foldername = GlobalStore.get("foldername")
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

        local worldDir = GlobalStore.get("worldDir")
        local selectWorld = GlobalStore.get("selectWorld")
        local worldTag = GlobalStore.get("worldTag")
        local dataSourceInfo = GlobalStore.get("dataSourceInfo")
        local localFiles = LocalService:new():LoadFiles(worldDir.default)

        self:SetCurrentCommidId(lastCommitSha)

        GlobalStore.set("localFiles", localFiles)

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
        worldInfo.revision = GlobalStore.get("currentRevision")
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

        LoginMain.setPageRefreshing(true)

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

    GitService:new():getProjectIdByName(
        foldername.base32,
        function(pProjectId)
            projectId = pProjectId

            GitService:new():getCommits(projectId, foldername.base32, false, handleKeepworkList)
        end
    )
end

function SyncMain:SetCurrentCommidId(commitId)
    local worldDir = GlobalStore.get("worldDir")

    WorldShare:SetWorldData("revision", {id = commitId}, worldDir.default)

    ParaIO.CreateDirectory(format("%smod/", worldDir.default))
    WorldShare:SaveWorldData(worldDir.default)
end

function SyncMain:GetCurrentRevisionInfo()
    local worldDir = GlobalStore.get("worldDir")

    return WorldShare:GetWorldData("revision", worldDir.default)
end

function SyncMain:checkWorldSize()
    local worldDir = GlobalStore.get("worldDir")
    local userType = GlobalStore.get("userType")

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
    local selectWorld = GlobalStore.get("selectWorld")
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
