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
local Progress = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")

local SyncToLocal = NPL.export()

local UPDATE = "UPDATE"
local DELETE = "DELETE"
local DOWNLOAD = "DOWNLOAD"

function SyncToLocal:Init(callback)
    local currentWorld = Store:Get('world/currentWorld')

    self.broke = false
    self.finish = false
    self.foldername = Store:Get("world/foldername")
    self.worldDir = currentWorld and currentWorld.worldpath
    self.callback = callback

    -- we build a world folder path if worldpath is not exit
    if (not self.worldDir or self.worldDir == "") then
        self.worldDir = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), self.foldername.default)
        currentWorld.worldpath = self.worldDir
        currentWorld.remotefile = "local://" .. currentWorld.worldpath

        InternetLoadWorld.cur_ds[InternetLoadWorld.selected_world_index] = currentWorld

        Store:Set('world/currentWorld', currentWorld)
    end

    if (not self.worldDir or self.worldDir == "") then
        _guihelper.MessageBox(L"下载失败，原因：下载目录为空")
        return false
    end

    self:SetFinish(false)
    self:SyncToLocal()
end

function SyncToLocal:SyncToLocal()
    local currentWorld = Store:Get("world/currentWorld")
    local commitId = Store:Get("world/commitId")

    self.compareListIndex = 1
    self.compareListTotal = 0

    local function Handle(data, err)
        if (commitId or currentWorld.status == 2 and #data ~= 0) then
            self:DownloadZIP()
            return false
        end

        Mod.WorldShare.MsgBox:Close()

        if (#data == 0) then
            UserConsole:ClosePage()
            CreateWorld:CreateNewWorld(currentWorld.foldername)
            return false
        end

        -- 加载进度UI界面
        Progress:Init(self)
        Progress:UpdateDataBar(0, 0, L"正在对比文件列表...")

        self.localFiles = LocalService:LoadFiles(self.worldDir)
        self.dataSourceFiles = data

        Store:Set("world/localFiles", localFiles)

        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:GetTree(self.foldername.base32, nil, Handle)
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
    WorldList:RefreshCurrentServerList()
    Progress:SetFinish(true)
    Progress:Refresh()
end

function SyncToLocal:HandleCompareList()
    if (self.compareListTotal < self.compareListIndex) then

        self:SetFinish(true)
        self:RefreshList()

        local currentWorld = Store:Get("world/currentWorld")
        KeepworkService:SetCurrentCommidId(currentWorld.lastCommitId)

        self.compareListIndex = 1
        
        if type(self.callback) == 'function' then
            self.callback()
            self.callback = nil
        end

        return false
    end

    if (self.broke) then
        self:SetFinish(true)
        LOG.std("SyncToLocal", "debug", "SyncToLocal", "下载被中断")
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

    if (currentItem.status == UPDATE) then
        self:UpdateOne(currentItem.file, Retry)
    end

    if (currentItem.status == DOWNLOAD) then
        self:DownloadOne(currentItem.file, Retry)
    end

    if (currentItem.status == DELETE) then
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
        self.foldername.base32,
        currentRemoteItem.path,
        nil,
        function(content, size)
            Progress:UpdateDataBar(
                self.compareListIndex,
                self.compareListTotal,
                format(L"%s （%s） 下载中", currentRemoteItem.path, Utils.FormatFileSize(size, "KB"))
            )

            LocalService:Write(self.foldername.default, Encoding.Utf8ToDefault(currentRemoteItem.path), content)

            if (type(callback) == "function") then
                callback()
            end
        end
    )
end

-- 更新本地文件
function SyncToLocal:UpdateOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    if (currentLocalItem.sha1 == currentRemoteItem.id) then
        if (type(callback) == "function") then
            Utils.SetTimeOut(callback)
        end

        return false
    end

    local function Handle(content, size)
        Progress:UpdateDataBar(
            self.compareListIndex,
            self.compareListTotal,
            format(L"%s （%s） 更新中", currentRemoteItem.path, Utils.FormatFileSize(size, "KB"))
        )

        LocalService:Write(self.foldername.default, Encoding.Utf8ToDefault(currentRemoteItem.path), content)

        if (type(callback) == "function") then
            callback()
        end
    end

    GitService:GetContentWithRaw(self.foldername.base32, currentRemoteItem.path, nil, Handle)
end

-- 删除文件
function SyncToLocal:DeleteOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 删除中", currentLocalItem.filename, Utils.FormatFileSize(currentLocalItem.size, "KB"))
    )

    LocalService:Delete(self.foldername.default, Encoding.Utf8ToDefault(currentLocalItem.filename))

    if (type(callback) == "function") then
        callback()
    end
end

function SyncToLocal:DownloadZIP()
    local commitId = Store:Get("world/commitId")

    local function Handle(commitId)
        if (not commitId) then
            return false
        end

        ParaIO.CreateDirectory(self.worldDir)

        self.localFiles = LocalService:LoadFiles(self.worldDir)

        if (#self.localFiles ~= 0) then
            LOG.std(nil, "warn", "WorldShare", "target directory: %s is not empty, we will overwrite files in the folder", Encoding.DefaultToUtf8(self.worldDir))
            GameLogic.RunCommand(format("/menu %s", "file.worldrevision"))
        end

        GitService:DownloadZIP(
            self.foldername.base32,
            commitId,
            function(bSuccess, downloadPath)
                LocalService:MoveZipToFolder(downloadPath)

                if type(self.callback) == 'function' then
                    self.callback()
                    self.callback = nil
                end

                self:RefreshList()
                Mod.WorldShare.MsgBox:Close()

                KeepworkService:SetCurrentCommidId(commitId)
                Store:Remove("world/commitId")
            end
        )
    end

    if (not commitId) then
        GitService:GetCommits(
            self.foldername.base32,
            false,
            function(data, err)
                if (data and data[1] and data[1]["id"]) then
                    Handle(data[1]["id"])
                end
            end
        )
    else
        Handle(commitId)
    end
end