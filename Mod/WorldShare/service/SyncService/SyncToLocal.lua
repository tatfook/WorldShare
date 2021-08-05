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

-- libs
local Encoding = commonlib.gettable("commonlib.Encoding")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")

-- service
local KeepworkService = NPL.load("../KeepworkService.lua")
local KeepworkServiceProject = NPL.load('../KeepworkService/Project.lua')
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")

-- bottles
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")

local SyncToLocal = NPL.export()

local UPDATE = "UPDATE"
local DELETE = "DELETE"
local DOWNLOAD = "DOWNLOAD"

function SyncToLocal:Init(callback)
    if type(callback) ~= 'function' then
        return false
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        return false
    end

    self.currentWorld = currentWorld
    self.broke = false
    self.finish = false
    self.callback = callback

    -- we build a world folder path if worldpath is not exit
    if not self.currentWorld.worldpath or self.currentWorld.worldpath == "" then
        local userId = Mod.WorldShare.Store:Get("user/userId")
        -- update shared world path
        if self.currentWorld.user and self.currentWorld.user.id and tonumber(self.currentWorld.user.id) ~= tonumber(userId) then
            self.currentWorld.worldpath = Encoding.Utf8ToDefault(
                format(
                    "%s/_shared/%s/%s/",
                    Mod.WorldShare.Utils.GetWorldFolderFullPath(),
                    self.currentWorld.user.username,
                    self.currentWorld.foldername
                )
            )
        else
            self.currentWorld.worldpath = Encoding.Utf8ToDefault(format("%s/%s/", Mod.WorldShare.Utils.GetWorldFolderFullPath(), self.currentWorld.foldername))
        end
        self.currentWorld.remotefile = "local://" .. self.currentWorld.worldpath

        InternetLoadWorld.cur_ds[InternetLoadWorld.selected_world_index] = self.currentWorld
    end

    if not self.currentWorld.worldpath or self.currentWorld.worldpath == "" then
        self.callback(false, L"下载失败，原因：下载目录为空")
        return false
    end

    self:SetFinish(false)

    if not self.currentWorld.lastCommitId then
        self.callback(false, L"commitId不存在")
        return false
    end

    self:Start()

    return self
end

function SyncToLocal:Start()
    self.compareListIndex = 1
    self.compareListTotal = 0

    self.callback(false, { method = 'UPDATE-PROGRESS', current = 0, total = 0, msg = L"正在对比文件列表..." })

    local function Handle(data, err)
        if type(data) ~= 'table' then
            self.callback(false, L"获取列表失败（下载）")
            self:SetFinish(true)
            return
        end

        if self.currentWorld.status == 2 and #data ~= 0 then
            self:DownloadZIP()
            return
        end

        if #data == 0 then
            self.callback(false, 'NEWWORLD')
            self:SetFinish(true)
            return false
        end

        self.localFiles = commonlib.vector:new()
        self.localFiles:AddAll(LocalService:LoadFiles(self.currentWorld.worldpath))
        self.dataSourceFiles = data

        self:IgnoreFiles()
        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:GetTree(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        self.currentWorld.lastCommitId,
        Handle
    )
end

function SyncToLocal:IgnoreFiles()
    local filePath = format("%s/.paraignore", self.currentWorld.worldpath)
    local file = ParaIO.open(filePath, "r")
    local content = file:GetText(0, -1)
    file:close()

    local ignoreFiles = {}

    if #content > 0 then
        for item in string.gmatch(content, "[^\r\n]+") do
            ignoreFiles[#ignoreFiles + 1] = item
        end
    end
    
    for LKey, LItem in ipairs(self.localFiles) do
        for FKey, FItem in ipairs(ignoreFiles) do
            if string.find(LItem.filename, FItem) then
                self.localFiles:remove(LKey)
            end
        end
    end
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
            if LItem.filename == DItem.path then
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

function SyncToLocal:Close()
    self.callback(true, 'success')
end

function SyncToLocal:HandleCompareList()
    if self.compareListTotal < self.compareListIndex then
        Mod.WorldShare.Store:Set('world/currentWorld', self.currentWorld)
        KeepworkService:SetCurrentCommitId()
        -- sync finish
        self:SetFinish(true)
        self.callback(false, {
            method = 'UPDATE-PROGRESS-FINISH'
        })

        self.compareListIndex = 1
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

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L"%s 下载中", currentRemoteItem.path)
    })

    GitService:GetContentWithRaw(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        currentRemoteItem.path,
        self.currentWorld.lastCommitId,
        function(content, err)
            if content == false then
                self.compareListIndex = 1
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FAIL',
                    msg = format(L'同步失败，原因： %s 下载失败', currentRemoteItem.path)
                })
                self:SetBroke(true)
                return false
            end

            LocalService:Write(self.currentWorld.worldpath, currentRemoteItem.path, content)

            self.callback(false, {
                method = 'UPDATE-PROGRESS',
                current = self.compareListIndex,
                total = self.compareListTotal,
                msg = format(L"%s （%s） 下载成功", currentRemoteItem.path, Mod.WorldShare.Utils.FormatFileSize(size, "KB"))
            })

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
        self.callback(false, {
            method = 'UPDATE-PROGRESS',
            current = self.compareListIndex,
            total = self.compareListTotal,
            msg = format(L"%s 相等跳过", currentRemoteItem.path)
        })

        if type(callback) == "function" then
            Mod.WorldShare.Utils.SetTimeOut(callback, 10)
        end

        return false
    end

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L"%s 更新中", currentRemoteItem.path)
    })

    GitService:GetContentWithRaw(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        currentRemoteItem.path,
        self.currentWorld.lastCommitId,
        function(content, size)
            if content == false then
                self.compareListIndex = 1
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FAIL',
                    msg = format(L'同步失败，原因： %s 更新失败', currentRemoteItem.path)
                })
                self:SetBroke(true)
                return false
            end

            LocalService:Write(self.currentWorld.worldpath, currentRemoteItem.path, content)

            self.callback(false, {
                method = 'UPDATE-PROGRESS',
                current = self.compareListIndex,
                total = self.compareListTotal,
                msg = format(L"%s （%s） 更新成功", currentRemoteItem.path, Mod.WorldShare.Utils.FormatFileSize(size, "KB"))
            })
    
            if type(callback) == "function" then
                callback()
            end
        end
    )
end

-- 删除文件
function SyncToLocal:DeleteOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L"%s （%s） 删除中", currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.size, "KB"))
    })

    LocalService:Delete(self.currentWorld.worldpath, currentLocalItem.filename)

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L"%s （%s） 删除成功", currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.size, "KB"))
    })

    if type(callback) == "function" then
        callback()
    end
end

function SyncToLocal:DownloadZIP()
    if not self.currentWorld or not self.currentWorld.kpProjectId or self.currentWorld.kpProjectId == 0 then
        return false
    end

    ParaIO.CreateDirectory(self.currentWorld.worldpath)

    self.localFiles = LocalService:LoadFiles(self.currentWorld.worldpath)

    if #self.localFiles ~= 0 then
        LOG.std(nil, "warn", "WorldShare", "target directory: %s is not empty, we will overwrite files in the folder", Encoding.DefaultToUtf8(self.currentWorld.worldpath))
        GameLogic.RunCommand(format("/menu %s", "file.worldrevision"))
    end

    LocalServiceWorld:DownLoadZipWorld(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        self.currentWorld.lastCommitId,
        self.currentWorld.worldpath,
        function()
            KeepworkService:SetCurrentCommitId()

            -- update worldinfo because world from internet
            local tag = LocalService:GetTag(self.currentWorld.worldpath)

            if tag then
                self.currentWorld.name = tag.name
                Mod.WorldShare.Store:Set('world/currentWorld', self.currentWorld)
            end

            self:SetFinish(true)
            self.callback(false, {
                method = 'UPDATE-PROGRESS-FINISH'
            })
        end
    )
end