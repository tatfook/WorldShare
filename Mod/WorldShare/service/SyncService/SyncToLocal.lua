--[[
Title: SyncToLocal
Author(s):  big
Date:  2018.6.20
Place: Foshan 
use the lib:
------------------------------------------------------------
local SyncToLocal = NPL.load("(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua")
------------------------------------------------------------
]]
local Encoding = commonlib.gettable("commonlib.Encoding")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")

local KeepworkService = NPL.load("../KeepworkService.lua")
local KeepworkServiceProject = NPL.load('../KeepworkService/Project.lua')
local Progress = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")

local SyncToLocal = NPL.export()

local UPDATE = "UPDATE"
local DELETE = "DELETE"
local DOWNLOAD = "DOWNLOAD"

function SyncToLocal:Init(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        return false
    end

    self.currentWorld = currentWorld
    self.broke = false
    self.finish = false
    self.callback = callback

    -- //TODO: Move to UI file
    -- 加载进度UI界面
    Progress:Init(self)

    -- we build a world folder path if worldpath is not exit
    if not self.currentWorld.worldpath or self.currentWorld.worldpath == "" then
        self.currentWorld.worldpath = Encoding.Utf8ToDefault(format("%s/%s/", Mod.WorldShare.Utils.GetWorldFolderFullPath(), self.currentWorld.foldername))
        self.currentWorld.remotefile = "local://" .. self.currentWorld.worldpath

        InternetLoadWorld.cur_ds[InternetLoadWorld.selected_world_index] = self.currentWorld

        Mod.WorldShare.Store:Set('world/currentWorld', self.currentWorld)
    end

    if not self.currentWorld.worldpath or self.currentWorld.worldpath == "" then
        self.callback(false, L"下载失败，原因：下载目录为空")
        self.callback = nil
        return false
    end

    self:SetFinish(false)
    self:Start()
end

function SyncToLocal:Start()
    self.compareListIndex = 1
    self.compareListTotal = 0

    Progress:UpdateDataBar(0, 0, L"正在对比文件列表...")

    local function Handle(data, err)
        if type(data) ~= 'table' then
            self.callback(false, L"获取列表失败")
            self.callback = nil
            self:SetFinish(true)
            Progress:ClosePage()
            return false
        end

        if self.currentWorld.status == 2 and #data ~= 0 then
            self:DownloadZIP()
            return false
        end

        if #data == 0 then
            self.callback(false, 'NEWWORLD')
            self.callback = nil
            self:SetFinish(true)
            Progress:ClosePage()
            return false
        end

        self.localFiles = LocalService:LoadFiles(self.currentWorld.worldpath)
        self.dataSourceFiles = data

        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:GetTree(self.currentWorld.foldername, self.currentWorld.lastCommitId, Handle)
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

        if not bIsExisted then
            local currentItem = {
                file = LItem.filename,
                status = DELETE
            }

            self.compareList:push_back(currentItem)
        end
    end

    self.compareListTotal = #self.compareList
end

function SyncToLocal:HandleCompareList()
    if self.compareListTotal < self.compareListIndex then
        KeepworkService:SetCurrentCommitId()

        self.compareListIndex = 1
        self:SetFinish(true)

        Progress:SetFinish(true)
        Progress:Refresh()

        Mod.WorldShare.Store:Set(
            "world/CloseProgress",
            function()
                self.callback(true, 'success')
                self.callback = nil
            end
        )

        return true
    end

    if self.broke then
        self.compareListIndex = 1
        self:SetFinish(true)
        LOG.std("SyncToLocal", "debug", "SyncToLocal", L"下载被中断")
        return false
    end

    local currentItem = self.compareList[self.compareListIndex]

    local function Retry()
        Progress:UpdateDataBar(
            self.compareListIndex,
            self.compareListTotal,
            format(L"%s 处理完成", currentItem.file),
            self.finish
        )

        self.compareListIndex = self.compareListIndex + 1
        self:HandleCompareList()
    end

    if currentItem.status == UPDATE then
        self:UpdateOne(currentItem.file, Retry)
    end

    if currentItem.status == DOWNLOAD then
        self:DownloadOne(currentItem.file, Retry)
    end

    if currentItem.status == DELETE then
        self:DeleteOne(currentItem.file, Retry)
    end
end

function SyncToLocal:SetFinish(value)
    self.finish = value
end

function SyncToLocal:SetBroke(value)
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
function SyncToLocal:DownloadOne(file, callback)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    GitService:GetContentWithRaw(
        self.currentWorld.foldername,
        currentRemoteItem.path,
        self.currentWorld.lastCommitId,
        function(content, size)
            Progress:UpdateDataBar(
                self.compareListIndex,
                self.compareListTotal,
                format(L"%s （%s） 下载中", currentRemoteItem.path, Utils.FormatFileSize(size, "KB"))
            )

            LocalService:Write(self.currentWorld.foldername, currentRemoteItem.path, content)

            if type(callback) == "function" then
                callback()
            end
        end
    )
end

-- 更新本地文件
function SyncToLocal:UpdateOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    if currentLocalItem.sha1 == currentRemoteItem.id then
        if type(callback) == "function" then
            Mod.WorldShare.Utils.SetTimeOut(callback)
        end

        return false
    end

    local function Handle(content, size)
        Progress:UpdateDataBar(
            self.compareListIndex,
            self.compareListTotal,
            format(L"%s （%s） 更新中", currentRemoteItem.path, Utils.FormatFileSize(size, "KB"))
        )

        LocalService:Write(self.currentWorld.foldername, currentRemoteItem.path, content)

        if type(callback) == "function" then
            callback()
        end
    end

    GitService:GetContentWithRaw(self.currentWorld.foldername, currentRemoteItem.path, self.currentWorld.lastCommitId, Handle)
end

-- 删除文件
function SyncToLocal:DeleteOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 删除中", currentLocalItem.filename, Utils.FormatFileSize(currentLocalItem.size, "KB"))
    )

    LocalService:Delete(self.currentWorld.foldername, currentLocalItem.filename)

    if type(callback) == "function" then
        callback()
    end
end

function SyncToLocal:DownloadZIP()
    if not self.currentWorld or not self.currentWorld.kpProjectId then
        return false
    end

    ParaIO.CreateDirectory(self.currentWorld.worldpath)

    self.localFiles = LocalService:LoadFiles(self.currentWorld.worldpath)

    if #self.localFiles ~= 0 then
        LOG.std(nil, "warn", "WorldShare", "target directory: %s is not empty, we will overwrite files in the folder", Encoding.DefaultToUtf8(self.currentWorld.worldpath))
        GameLogic.RunCommand(format("/menu %s", "file.worldrevision"))
    end

    GitService:DownloadZIP(
        self.currentWorld.foldername,
        self.currentWorld.lastCommitId,
        function(bSuccess, downloadPath)
            LocalService:MoveZipToFolder(self.currentWorld.foldername, downloadPath)

            if type(self.callback) == 'function' then
                self.callback(true, 'success')
                self.callback = nil
            end

            self:SetFinish(true)
            Progress:UpdateDataBar(
                1,
                1,
                format(L"处理完成"),
                self.finish
            )
            Progress:SetFinish(true)
            Progress:Refresh()

            KeepworkService:SetCurrentCommitId()
        end
    )
end