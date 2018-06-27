--[[
Title: SyncToLocal
Author(s):  big
Date:  2018.6.20
Place: Foshan 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncToLocal.lua")
local SyncToLocal = commonlib.gettable("Mod.WorldShare.sync.SyncToLocal")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua")
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local SyncGUI = commonlib.gettable("Mod.WorldShare.sync.SyncGUI")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local Encoding = commonlib.gettable("commonlib.Encoding")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")

local SyncToLocal = commonlib.gettable("Mod.WorldShare.sync.SyncToLocal")

local UPDATE = "UPDATE"
local DELETE = "DELETE"
local DOWNLOAD = "DOWNLOAD"

function SyncToLocal:init(callback)
    self.worldDir = GlobalStore.get("worldDir")
    self.foldername = GlobalStore.get("foldername")
    local selectWorld = GlobalStore.get("selectWorld")
    local commitId = GlobalStore.get("commitId")

    if (not self.worldDir or not self.worldDir.default or self.worldDir.default == "") then
        _guihelper.MessageBox(L "下载失败，原因：下载目录为空")
        return false
    end

    local function handleProjectId(projectId)
        if (not projectId) then
            _guihelper.MessageBox(L "数据源异常")
            SyncGUI.closeWindow()
            return false
        end

        self.projectId = projectId
        selectWorld.projectId = projectId
        GlobalStore.set("selectWorld", selectWorld)

        if (commitId or selectWorld.status == 2) then
            -- down zip
            self:DownloadZIP()
            return false
        end

        -- 加载进度UI界面
        SyncGUI.init()
        SyncGUI.SetSync(self)

        self:SetFinish(false)

        self:syncToLocal()
    end

    GitService:new():getProjectIdByName(self.foldername.base32, handleProjectId)
end

function SyncToLocal:syncToLocal()
    self.compareListIndex = 1
    self.compareListTotal = 0

    SyncGUI:updateDataBar(0, 0, L "正在对比文件列表...")

    local function handleSyncToLocal(data, err)
        self.localFiles = LocalService:new():LoadFiles(self.worldDir.default)
        self.dataSourceFiles = data

        GlobalStore.set("localFiles", localFiles)

        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:new():getTree(self.projectId, nil, nil, handleSyncToLocal)
end

function SyncToLocal:GetCompareList()
    self.compareList = commonlib.vector:new()

    for DKey, DItem in ipairs(self.dataSourceFiles) do
        local bIsExisted = false

        for LKey, LItem in ipairs(self.localFiles) do
            if (DItem.path == LItem.filename) then
                bIsExisted = true
                break
            end
        end

        local currentItem = {
            file = DItem.path,
            status = bIsExisted and UPDATE or DOWNLOAD
        }

        self.compareList:push_back(currentItem)
    end

    for LKey, LItem in ipairs(self.localFiles) do
        local bIsExisted = false

        for DKey, DItem in ipairs(self.dataSourceFiles) do
            if (LItem.filename == DItem.path) then
                bIsExisted = true
                break
            end
        end

        if (not bIsExisted) then
            local currentItem = {
                file = LItem.filename,
                status = DELETE
            }

            self.compareList:push_back(currentItem)
        end
    end

    self.compareListTotal = #self.compareList
end

function SyncToLocal:RefreshList()
    LoginWorldList.RefreshCurrentServerList(
        function()
            local willEnterWorld = GlobalStore.get('willEnterWorld')

            if(type(willEnterWorld) == 'function') then
                willEnterWorld()

                GlobalStore.remove('willEnterWorld')
            end

            SyncGUI.SetFinish(true)
            SyncGUI:refresh()
        end
    )
end

function SyncToLocal:HandleCompareList()
    if (self.compareListTotal < self.compareListIndex) then

        self:SetFinish(true)
        self:RefreshList()

        local selectWorld = GlobalStore.get("selectWorld")
        SyncMain:SetCurrentCommidId(selectWorld.lastCommitId)

        self.compareListIndex = 1
        return false
    end

    if (self.broke) then
        self:SetFinish(true)
        LOG.std("SyncToDataSource", "debug", "下载被中断")
        return false
    end

    local currentItem = self.compareList[self.compareListIndex]

    local function retry()
        SyncGUI:updateDataBar(
            self.compareListIndex,
            self.compareListTotal,
            format(L "%s 处理完成", currentItem.file),
            self.finish
        )

        self.compareListIndex = self.compareListIndex + 1
        self:HandleCompareList()
    end

    if (currentItem.status == UPDATE) then
        self:updateOne(currentItem.file, retry)
    end

    if (currentItem.status == DOWNLOAD) then
        self:downloadOne(currentItem.file, retry)
    end

    if (currentItem.status == DELETE) then
        self:deleteOne(currentItem.file, retry)
    end
end

function SyncToLocal:SetFinish(value)
    self.finish = value
end

function SyncToLocal:SetBorke(value)
    self.broke = value
end

function SyncToLocal:GetLocalFileByFilename(filename)
    for key, item in ipairs(self.localFiles) do
        if (item.filename == filename) then
            return item
        end
    end
end

function SyncToLocal:GetRemoteFileByPath(path)
    for key, item in ipairs(self.dataSourceFiles) do
        if (item.path == path) then
            return item
        end
    end
end

-- 下载新文件
function SyncToLocal:downloadOne(file, callback)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    GitService:new():getContentWithRaw(
        self.foldername.base32,
        currentRemoteItem.path,
        nil,
        function(content, size)
            SyncGUI:updateDataBar(
                self.compareListIndex,
                self.compareListTotal,
                format(L "%s （%s） 更新中", currentRemoteItem.path, Utils.formatFileSize(size, "KB"))
            )

            LocalService:write(self.foldername.default, Encoding.Utf8ToDefault(currentRemoteItem.path), content)

            if (type(callback) == "function") then
                callback()
            end
        end
    )
end

-- 更新本地文件
function SyncToLocal:updateOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    if (currentLocalItem.sha1 == currentRemoteItem.sha) then
        if (type(callback) == "function") then
            Utils.SetTimeOut(callback)
        end

        return false
    end

    local function handleUpdate(content, size)
        SyncGUI:updateDataBar(
            self.compareListIndex,
            self.compareListTotal,
            format(L "%s （%s） 更新中", currentRemoteItem.path, Utils.formatFileSize(size, "KB"))
        )

        LocalService:write(self.foldername.default, Encoding.Utf8ToDefault(currentRemoteItem.path), content)

        if (type(callback) == "function") then
            callback()
        end
    end

    GitService:new():getContentWithRaw(self.foldername.base32, currentRemoteItem.path, nil, handleUpdate)
end

-- 删除文件
function SyncToLocal:deleteOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)

    SyncGUI:updateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L "%s （%s） 更新中", currentLocalItem.filename, Utils.formatFileSize(currentLocalItem.size, "KB"))
    )

    LocalService:delete(self.foldername.default, Encoding.Utf8ToDefault(currentLocalItem.filename))

    if (type(callback) == "function") then
        callback()
    end
end

function SyncToLocal:DownloadZIP()
    local commitId = GlobalStore.get("commitId")

    local function handleDownloadZIP(commitId)
        if (not commitId) then
            return false
        end

        ParaIO.CreateDirectory(self.worldDir.default)

        self.localFiles = LocalService:new():LoadFiles(self.worldDir.default)

        if (#self.localFiles ~= 0) then
            _guihelper.MessageBox(L "本地数据错误")
            return false
        end

        GitService:new():DownloadZIP(
            self.foldername.base32,
            commitId,
            function(bSuccess, downloadPath)
                LocalService:new():MoveZipToFolder(downloadPath)
                self:RefreshList()

                SyncMain:SetCurrentCommidId(commitId)
                GlobalStore.remove("commitId")
            end
        )
    end

    if (not commitId) then
        GitService:new():getCommits(
            self.projectId,
            self.foldername.base32,
            false,
            function(data, err)
                if (data and data[1] and data[1]["id"]) then
                    handleDownloadZIP(data[1]["id"])
                end
            end
        )
    else
        handleDownloadZIP(commitId)
    end
end
