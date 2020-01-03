--[[
Title: SyncToDataSource
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
local SyncToDataSource = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncToDataSource.lua")
------------------------------------------------------------
]]
local Progress = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua")
local GitService = NPL.load("../GitService.lua")
local LocalService = NPL.load("../LocalService.lua")
local KeepworkService = NPL.load("../KeepworkService.lua")
local KeepworkServiceProject = NPL.load("../KeepworkService/Project.lua")
local KeepworkServiceWorld = NPL.load("../KeepworkService/World.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local KeepworkGen = NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local StorageFilesApi = NPL.load("(gl)Mod/WorldShare/api/Storage/Files.lua")
local QiniuRootApi = NPL.load("(gl)Mod/WorldShare/api/Qiniu/Root.lua")

local SyncToDataSource = NPL.export()

local UPDATE = "UPDATE"
local UPLOAD = "UPLOAD"
local DELETE = "DELETE"

function SyncToDataSource:Init(callback)
    if type(callback) ~= 'function' then
        return false
    end

    self.callback = callback

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    self.currentWorld = currentWorld

    if not self.currentWorld.worldpath or self.currentWorld.worldpath == "" then
        callback(false, L"上传失败，将使用离线模式，原因：上传目录为空")
        return false
    end

    -- 加载进度UI界面
    -- // TODO: move to UI file
    Progress:Init(self)

    self:SetFinish(false)
    self:SetBroke(false)

    self:IsProjectExist(
        function(beExisted)
            if beExisted then
                -- update world
                KeepworkServiceProject:GetProjectIdByWorldName(self.currentWorld.foldername, function()
                    currentWorld = Mod.WorldShare.Store:Get('world/currentWorld') 

                    if currentWorld and currentWorld.kpProjectId then
                        local tag = LocalService:GetTag(currentWorld.worldpath)

                        if type(tag) == 'table' then
                            tag.kpProjectId = currentWorld.kpProjectId
                            LocalService:SetTag(currentWorld.worldpath, tag)
                        end
                    end

                    self:Start()
                end)
            else
                KeepworkServiceProject:CreateProject(
                    self.currentWorld.foldername,
                    function(data, err)
                        if err == 400 and data and data.code == 17 then
                            callback(false, L"您创建的帕拉卡(Paracraft)在线项目数量过多。请删除不需要的项目后再试。")
                            self:SetFinish(true)
                            Progress:ClosePage()
                            return false
                        end

                        if err ~= 200 or not data or not data.id then
                            callback(false, L"创建项目失败")
                            self:SetFinish(true)
                            Progress:ClosePage()
                            return false
                        end

                        currentWorld.kpProjectId = data.id

                        if currentWorld and currentWorld.kpProjectId then
                            local tag = LocalService:GetTag(currentWorld.worldpath)

                            if type(tag) == 'table' then
                                tag.kpProjectId = currentWorld.kpProjectId

                                LocalService:SetTag(currentWorld.worldpath, tag)
                            end
                        end

                        Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                        self:Start()
                    end
                )
            end
        end
    )
end

function SyncToDataSource:IsProjectExist(callback)
    KeepworkServiceProject:GetProjectByWorldName(
        self.currentWorld.foldername,
        function(data)
            if type(callback) ~= "function" then
                return false
            end

            if type(data) == 'table' then
                callback(true)
            else
                callback(false)
            end
        end
    )
end

function SyncToDataSource:Start()
    self.compareListIndex = 1
    self.compareListTotal = 0

    Progress:UpdateDataBar(0, 0, L"正在对比文件列表...")

    local function Handle(data, err)
        if type(data) ~= 'table' then
            self.callback(false, L"获取列表失败")
            self:SetFinish(true)
            Progress:ClosePage()
            return false
        end

        self.dataSourceFiles = data
        self.localFiles = commonlib.vector:new()
        self.localFiles:AddAll(LocalService:LoadFiles(self.currentWorld.worldpath)) --再次获取本地文件，保证上传的内容为最新

        self:IgnoreFiles()
        self:CheckReadmeFile()
        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:GetTree(self.currentWorld.foldername, self.currentWorld.lastCommitId, Handle)
end

function SyncToDataSource:IgnoreFiles()
    local fileList = { "mod/" }

    for LKey, LItem in ipairs(self.localFiles) do
        for FKey, FItem in ipairs(fileList) do
            if string.find(LItem.filename, FItem) then
                self.localFiles:remove(LKey)
            end
        end
    end
end

function SyncToDataSource:CheckReadmeFile()
    if not self.localFiles then
        return false
    end

    local hasReadme = false

    for key, value in ipairs(self.localFiles) do
        if string.upper(value.filename) == "README.MD" then
            if (value.filename == "README.md") then
                hasReadme = true
            else
                LocalService:Delete(self.currentWorld.foldername, value.filename)
                hasReadme = false
            end
        end
    end

    if not hasReadme then
        local filePath = format("%s/README.md", self.currentWorld.worldpath)
        local file = ParaIO.open(filePath, "w")
        local content = KeepworkGen:GetReadmeFile()

        file:write(content, #content)
        file:close()

        local readMeFiles = {
            filename = "README.md",
            file_path = filePath,
            file_content_t = content
        }

        self.localFiles:push_back(readMeFiles)
    end
end

function SyncToDataSource:GetCompareList()
    self.compareList = commonlib.vector:new()

    for LKey, LItem in ipairs(self.localFiles) do
        local bIsExisted = false

        for IKey, IItem in ipairs(self.dataSourceFiles) do
            if LItem.filename == IItem.path then
                bIsExisted = true
                break
            end
        end

        local currentItem = {
            file = LItem.filename,
            status = bIsExisted and UPDATE or UPLOAD
        }

        self.compareList:push_back(currentItem)
    end

    for IKey, IItem in ipairs(self.dataSourceFiles) do
        local bIsExisted = false

        for LKey, LItem in ipairs(self.localFiles) do
            if IItem.path == LItem.filename then
                bIsExisted = true
                break
            end
        end

        if not bIsExisted then
            local currentItem = {
                file = IItem.path,
                status = DELETE
            }

            self.compareList:push_back(currentItem)
        end
    end

    -- handle revision in last
    for CKey, CItem in ipairs(self.compareList) do
        if string.lower(CItem.file) == "revision.xml" then
            self.compareList:push_back(CItem)
            self.compareList:remove(CKey)
        end
    end

    self.compareListTotal = #self.compareList
end

function SyncToDataSource:RefreshList()
    self:UpdateRecord(
        function()
            Progress:SetFinish(true)
            Progress:Refresh()

            Mod.WorldShare.Store:Set(
                "world/CloseProgress",
                function()
                    self.callback(true, 'success')
                    self.callback = nil
                end
            )
        end
    )
end

function SyncToDataSource:HandleCompareList()
    if self.compareListTotal < self.compareListIndex then
        -- sync finish
        self:SetFinish(true)

        self:RefreshList()

        self.compareListIndex = 1
        return false
    end

    if self.broke then
        self:SetFinish(true)
        LOG.std("SyncToDataSource", "debug", "SyncToDataSource", "上传被中断")
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

    if currentItem.status == UPLOAD then
        self:UploadOne(currentItem.file, Retry)
    end

    if currentItem.status == DELETE then
        self:DeleteOne(currentItem.file, Retry)
    end
end

function SyncToDataSource:GetLocalFileByFilename(filename)
    for key, item in ipairs(self.localFiles) do
        if item.filename == filename then
            return item
        end
    end
end

function SyncToDataSource:GetRemoteFileByPath(path)
    for key, item in ipairs(self.dataSourceFiles) do
        if item.path == path then
            return item
        end
    end
end

function SyncToDataSource:SetBroke(value)
    self.broke = value
end

function SyncToDataSource:SetFinish(value)
    self.finish = value
end

-- 上传新文件
function SyncToDataSource:UploadOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)

    -- These line give a feedback on update record method
    if string.lower(currentLocalItem.filename) == 'preview.jpg' then
        Mod.WorldShare.Store:Set('world/isPreviewUpdated', true)
    end

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 上传中", currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, "KB"))
    )

    GitService:Upload(
        self.currentWorld.foldername,
        currentLocalItem.filename,
        currentLocalItem.file_content_t,
        function(bIsUpload)
            if bIsUpload then
                if type(callback) == "function" then
                    callback()
                end
            else
                self.callback(false, format(L"%s上传失败", currentLocalItem.filename))
                self:SetBroke(true)

                Progress:UpdateDataBar(
                    self.compareListIndex,
                    self.compareListTotal,
                    format(L"%s 上传失败", currentLocalItem.filename)
                )
            end
        end
    )
end

-- 更新数据源文件
function SyncToDataSource:UpdateOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 对比中", currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, "KB"))
    )

    -- These line give a feedback on update record method
    if string.lower(currentLocalItem.filename) == 'preview.jpg' then
        if currentLocalItem.sha1 == currentRemoteItem.id then
            Mod.WorldShare.Store:Set('world/isPreviewUpdated', false)
        else
            Mod.WorldShare.Store:Set('world/isPreviewUpdated', true)
        end
    end

    if currentLocalItem.sha1 == currentRemoteItem.id and string.lower(currentLocalItem.filename) ~= "revision.xml" then
        if type(callback) == "function" then
            Progress:UpdateDataBar(
                self.compareListIndex,
                self.compareListTotal,
                format(L"%s （%s） 文件一致，跳过", currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, "KB"))
            )

            Mod.WorldShare.Utils.SetTimeOut(callback)
        end

        return false
    end

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 更新中", currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, "KB"))
    )

    GitService:Update(
        self.currentWorld.foldername,
        currentLocalItem.filename,
        currentLocalItem.file_content_t,
        function(bIsUpdate)
            if bIsUpdate then
                if type(callback) == "function" then
                    callback()
                end
            else
                self.callback(false, L"更新失败")
                self:SetBroke(true)

                Progress:UpdateDataBar(
                    self.compareListIndex,
                    self.compareListTotal,
                    format(L"%s 更新失败", currentLocalItem.filename)
                )
            end
        end
    )
end

-- 删除数据源文件
function SyncToDataSource:DeleteOne(file, callback)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    -- These line give a feedback on update record method
    if string.lower(currentRemoteItem.name) == 'preview.jpg' then
        Mod.WorldShare.Store:Set('world/isPreviewUpdated', false)
    end

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s 删除中", currentRemoteItem.path)
    )

    GitService:DeleteFile(
        self.currentWorld.foldername,
        currentRemoteItem.path,
        function(bIsDelete)
            if bIsDelete then
                if type(callback) == "function" then
                    callback()
                end
            else
                self.callback(false, L"删除失败")
                self:SetBroke(true)

                Progress:UpdateDataBar(
                    self.compareListIndex,
                    self.compareListTotal,
                    format(L"%s 删除失败", currentRemoteItem.name)
                )
            end
        end
    )
end

-- update world info
function SyncToDataSource:UpdateRecord(callback)
    if not self.currentWorld then
        return false
    end

    local function Handle(data, err)
        if type(data) ~= "table" or
           not data.commitId or
           not data.message then
            self.callback(false, L"获取Commit列表失败")
            self:SetFinish(true)
            Progress:ClosePage()
            return false
        end

        local lastCommitFile = string.match(data.message, "revision.xml")
        local lastCommitSha = data.commitId

        self.currentWorld.lastCommitId = lastCommitSha

        if string.lower(lastCommitFile) ~= "revision.xml" then
            self.callback(false, L"上一次同步到数据源同步失败，请重新同步世界到数据源")
            return false
        end

        local localFiles = LocalService:LoadFiles(self.currentWorld.worldpath)
        local filesTotals = self.currentWorld.size or 0

        local function HandleGetWorld(data)
            local oldWorldInfo = data or false

            if not oldWorldInfo then
                return false
            end

            local commitIds = {}

            if oldWorldInfo.extra and oldWorldInfo.extra.commitIds then
                commitIds = oldWorldInfo.extra.commitIds
            end

            commitIds[#commitIds + 1] = {
                commitId = lastCommitSha,
                revision = Mod.WorldShare.Store:Get("world/currentRevision"),
                date = os.date("%Y%m%d", os.time())
            }

            local worldInfo = {}
            local username = Mod.WorldShare.Store:Get("user/username")
            local base32Foldername = GitEncoding.Base32(self.currentWorld.foldername or '')
            local repoPath = Mod.WorldShare.Utils.UrlEncode(username .. '/' .. base32Foldername)

            worldInfo.worldName = self.currentWorld.foldername
            worldInfo.revision = Mod.WorldShare.Store:Get("world/currentRevision")
            worldInfo.fileSize = filesTotals
            worldInfo.commitId = lastCommitSha
            worldInfo.username = username
            worldInfo.archiveUrl = format('%s/repos/%s/download?ref=%s', KeepworkService:GetCoreApi(), repoPath, lastCommitSha)

            local function AfterHandlePreview(preview)
                preview = preview or ""

                worldInfo.extra = {
                    coverUrl = preview,
                    commitIds = commitIds
                }

                if self.currentWorld.local_tagname and self.currentWorld.local_tagname ~= self.currentWorld.foldername then
                    worldInfo.extra.worldTagName = self.currentWorld.local_tagname
                end

                KeepworkServiceWorld:PushWorld(
                    worldInfo,
                    function(data, err)
                        if (err ~= 200) then
                            self.callback(false, L"更新服务器列表失败")
                            return false
                        end
        
                        if type(callback) == 'function' then
                            callback()
                        end
                    end
                )

                KeepworkServiceProject:GetProject(
                    self.currentWorld.kpProjectId,
                    function(data)
                        local extra = data and data.extra or {}

                        if Mod.WorldShare.Store:Get('world/isPreviewUpdated') and
                            self.currentWorld.local_tagname and
                            self.currentWorld.local_tagname ~= self.currentWorld.foldername then

                            extra.imageUrl = preview
                            extra.worldTagName = self.currentWorld.local_tagname

                            KeepworkServiceProject:UpdateProject(
                                self.currentWorld.kpProjectId,
                                {
                                    extra = extra
                                }
                            )
                        elseif Mod.WorldShare.Store:Get('world/isPreviewUpdated') then
                            extra.imageUrl = preview

                            KeepworkServiceProject:UpdateProject(
                                self.currentWorld.kpProjectId,
                                {
                                    extra = extra
                                }
                            )
                        elseif self.currentWorld.local_tagname and
                            self.currentWorld.local_tagname ~= self.currentWorld.foldername then
                            extra.worldTagName = self.currentWorld.local_tagname

                            KeepworkServiceProject:UpdateProject(
                                self.currentWorld.kpProjectId,
                                {
                                    extra = extra
                                }
                            )
                        end

                        Mod.WorldShare.Store:Remove('world/isPreviewUpdated')
                    end
                )

                Mod.WorldShare.Store:Set("world/currentWorld", self.currentWorld)
                KeepworkService:SetCurrentCommitId()
            end

            StorageFilesApi:Token('preview.jpg', function(data, err)
                if not data.token or not data.key then
                    return false
                end

                local targetDir = format("%s/%s/preview.jpg", Mod.WorldShare.Utils.GetWorldFolderFullPath(), commonlib.Encoding.Utf8ToDefault(self.currentWorld.foldername))
                local content = LocalService:GetFileContent(targetDir)

                if not content then
                    return false
                end

                QiniuRootApi:Upload(
                    data.token,
                    data.key,
                    self.currentWorld.kpProjectId .. '-preview-' .. lastCommitSha .. '.jpg',
                    content,
                    function()
                        StorageFilesApi:List(function(listData, err)
                            if listData and type(listData.data) ~= 'table' then
                                AfterHandlePreview()
                                return false
                            end

                            for key, item in ipairs(listData.data) do
                                if item.key == data.key then
                                    if item.downloadUrl then
                                        AfterHandlePreview(item.downloadUrl)
                                    end
                                end
                            end
                        end)
                    end
                )
            end)
        end

        KeepworkServiceWorld:GetWorld(self.currentWorld.foldername, HandleGetWorld)
    end

    GitService:GetCommits(self.currentWorld.foldername, Handle)
end