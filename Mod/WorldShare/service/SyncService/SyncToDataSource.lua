--[[
Title: SyncToDataSource
Author(s): big
CreateDate: 2018.06.20
ModifyDate: 2021.09.14
Desc: 
use the lib:
------------------------------------------------------------
local SyncToDataSource = NPL.load('(gl)Mod/WorldShare/service/SyncService/SyncToDataSource.lua')
------------------------------------------------------------
]]

-- libs
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')

-- service
local GitService = NPL.load('../GitService.lua')
local LocalService = NPL.load('../LocalService.lua')
local KeepworkService = NPL.load('../KeepworkService.lua')
local KeepworkServiceProject = NPL.load('../KeepworkService/Project.lua')
local KeepworkServiceWorld = NPL.load('../KeepworkService/KeepworkServiceWorld.lua')
local KeepworkServiceSession = NPL.load('../KeepworkService/Session.lua')
local Compare = NPL.load('./Compare.lua')
local EventTrackingService = NPL.load('../EventTracking.lua')

-- helper
local KeepworkGen = NPL.load('(gl)Mod/WorldShare/helper/KeepworkGen.lua')
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

-- api
local StorageFilesApi = NPL.load('(gl)Mod/WorldShare/api/Storage/Files.lua')
local QiniuRootApi = NPL.load('(gl)Mod/WorldShare/api/Qiniu/Root.lua')

local SyncToDataSource = NPL.export()

local UPDATE = 'UPDATE'
local UPLOAD = 'UPLOAD'
local DELETE = 'DELETE'

function SyncToDataSource:Init(callback)
    if type(callback) ~= 'function' then
        return false
    end

    self.callback = callback

    local function Handle()
        self.currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    
        if not self.currentWorld.worldpath or self.currentWorld.worldpath == '' then
            callback(false, L'上传失败，将使用离线模式，原因：上传目录为空')
            return false
        end

        Compare:CheckRevision(self.currentWorld.worldpath)

        self:SetFinish(false)
        self:SetBroke(false)

        self:IsProjectExist(
            function(beExisted)
                if beExisted then
                    -- update world
                    KeepworkServiceProject:GetProjectIdByWorldName(self.currentWorld.foldername, self.currentWorld.shared, function(pid)
                        currentWorld = Mod.WorldShare.Store:Get('world/currentWorld') 
    
                        if currentWorld and currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
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
                                callback(false, L'您创建的帕拉卡(Paracraft)在线项目数量过多。请删除不需要的项目后再试。')
                                self:SetFinish(true)
                                return false
                            end
    
                            if err ~= 200 or not data or not data.id then
                                callback(false, L'创建项目失败')
                                self:SetFinish(true)
                                return false
                            end
    
                            self.currentWorld.kpProjectId = data.id
    
                            if self.currentWorld and self.currentWorld.kpProjectId and self.currentWorld.kpProjectId ~= 0 then
                                local tag = LocalService:GetTag(self.currentWorld.worldpath)
    
                                if tag and type(tag) == 'table' then
                                    tag.kpProjectId = self.currentWorld.kpProjectId
    
                                    LocalService:SetTag(self.currentWorld.worldpath, tag)
                                end
                            end
    
                            Mod.WorldShare.Store:Set('world/currentWorld', self.currentWorld)
                            self:Start()
                        end
                    )
                end
            end
        )
    end

    KeepworkServiceSession:CheckTokenExpire(function(bIsSuccess)
        if bIsSuccess then
            Handle()
        else
            self.callback(false, L'RE-ENTRY')
        end
    end)

    -- return current sync instance to UI component
    return self
end

function SyncToDataSource:IsProjectExist(callback)
    if type(callback) ~= 'function' then
        return false
    end

    local worldUserId = 0

    if self.currentWorld.shared then
        if not self.currentWorld.user then
            _guihelper.MessageBox(L'您没有权限同步此世界')

            self.callback(false, L'您没有权限同步此世界')
            self:SetFinish(true)

            return
        end

        worldUserId = self.currentWorld.user.id
    end

    KeepworkServiceWorld:GetWorld(
        self.currentWorld.foldername,
        self.currentWorld.shared,
        worldUserId,
        function(data)
            if type(data) == 'table' then
                if self.currentWorld.shared then
                    local members = self.currentWorld.members or {}
                    local username = Mod.WorldShare.Store:Get('user/username')

                    for key, item in ipairs(members) do
                        if item == username then
                            callback(true)
                            return
                        end
                    end

                    self.callback(false, L'该项目不属于您，无法上传分享')
                    self:SetFinish(true)
                else
                    callback(true)
                end
            else
                callback(false)
            end
        end
    )
end

function SyncToDataSource:Start()
    self.compareListIndex = 1
    self.compareListTotal = 0

    self.callback(false, { method = 'UPDATE-PROGRESS', current = 0, total = 0, msg = L'正在对比文件列表...' })

    local function Handle(data, err)
        if type(data) ~= 'table' then
            self.callback(false, L'获取列表失败（上传）')
            self:SetFinish(true)
            return false
        end

        self.dataSourceFiles = data
        self.localFiles = commonlib.vector:new()
        self.localFiles:AddAll(LocalService:LoadFiles(self.currentWorld.worldpath)) --get latest files content

        self:IgnoreFiles()
        self:CheckReadmeFile()
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

function SyncToDataSource:IgnoreFiles()
    local filePath = format('%s/.paraignore', self.currentWorld.worldpath)
    local file = ParaIO.open(filePath, 'r')
    local content = file:GetText(0, -1)
    file:close()

    local ignoreFiles = {}

    if #content > 0 then
        for item in string.gmatch(content, '[^\r\n]+') do
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

function SyncToDataSource:CheckReadmeFile()
    if not self.localFiles then
        return false
    end

    local hasReadme = false

    for key, value in ipairs(self.localFiles) do
        if string.upper(value.filename) == 'README.MD' then
            if (value.filename == 'README.md') then
                hasReadme = true
            else
                LocalService:Delete(self.currentWorld.worldpath, value.filename)
                hasReadme = false
            end
        end
    end

    if not hasReadme then
        local filePath = format('%s/README.md', self.currentWorld.worldpath)
        local file = ParaIO.open(filePath, 'w')
        local content = KeepworkGen:GetReadmeFile()

        file:write(content, #content)
        file:close()

        local readMeFiles = {
            filename = 'README.md',
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
        if string.lower(CItem.file) == 'revision.xml' then
            self.compareList:push_back(CItem)
            self.compareList:remove(CKey)
        end
    end

    self.compareListTotal = #self.compareList
end

function SyncToDataSource:Close()
    self.callback(true, 'success')
end

function SyncToDataSource:HandleCompareList()
    if self.compareListTotal < self.compareListIndex then
        -- sync finish
        GameLogic.GetFilters():apply_filters('SyncWorldFinish');
        self:SetFinish(true)
        self:UpdateRecord(
            function()
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FINISH'
                })
            end
        )

        self.compareListIndex = 1
        return false
    end

    if self.broke then
        self:SetFinish(true)
        LOG.std('SyncToDataSource', 'debug', 'SyncToDataSource', '上传被中断')
        return false
    end

    local currentItem = self.compareList[self.compareListIndex]

    local function Retry()
        self.callback(false, {
            method = 'UPDATE-PROGRESS',
            current = self.compareListIndex,
            total = self.compareListTotal,
            msg = format(L'%s 处理完成', currentItem.file)
        })

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

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s （%s） 上传中', currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, 'KB'))
    })

    GitService:Upload(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        currentLocalItem.filename,
        currentLocalItem.file_content_t,
        function(bIsUpload)
            if bIsUpload then
                if type(callback) == 'function' then
                    callback()
                end
            else    
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FAIL',
                    msg = format(L'%s 上传失败', currentLocalItem.filename)
                })
                self:SetBroke(true)
            end
        end
    )
end

-- 更新数据源文件
function SyncToDataSource:UpdateOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s （%s） 对比中', currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, 'KB'))
    })

    -- These line give a feedback on update record method
    if string.lower(currentLocalItem.filename) == 'preview.jpg' then
        if currentLocalItem.sha1 == currentRemoteItem.id then
            Mod.WorldShare.Store:Set('world/isPreviewUpdated', false)
        else
            Mod.WorldShare.Store:Set('world/isPreviewUpdated', true)
        end
    end

    if currentLocalItem.sha1 == currentRemoteItem.id and string.lower(currentLocalItem.filename) ~= 'revision.xml' then
        if type(callback) == 'function' then
            self.callback(false, {
                method = 'UPDATE-PROGRESS',
                current = self.compareListIndex,
                total = self.compareListTotal,
                msg = format(L'%s （%s） 文件一致，跳过', currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, 'KB'))
            })

            Mod.WorldShare.Utils.SetTimeOut(callback, 10)
        end

        return false
    end

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s （%s） 更新中', currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.filesize, 'KB'))
    })

    GitService:Update(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        currentLocalItem.filename,
        currentLocalItem.file_content_t,
        function(bIsUpdate)
            if bIsUpdate then
                if type(callback) == 'function' then
                    callback()
                end
            else
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FAIL',
                    msg = format(L'%s 更新失败', currentLocalItem.filename)
                })
                self:SetBroke(true)
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

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s 删除中', currentRemoteItem.path)
    })

    GitService:DeleteFile(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        currentRemoteItem.path,
        function(bIsDelete)
            if bIsDelete then
                if type(callback) == 'function' then
                    callback()
                end
            else
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FAIL',
                    msg = format(L'%s 删除失败', currentRemoteItem.name)
                })
                self:SetBroke(true)
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
        if type(data) ~= 'table' or
           not data.commitId or
           not data.message then
            self.callback(false, L'获取COMMIT列表失败')
            self:SetFinish(true)
            return
        end

        local lastCommitFile = string.match(data.message, 'revision.xml')
        local lastCommitSha = data.commitId

        self.currentWorld.lastCommitId = lastCommitSha

        if not lastCommitFile or string.lower(lastCommitFile) ~= 'revision.xml' then
            self.callback(false, L'上一次同步到数据源同步失败，请重新同步世界到数据源')
            self:SetFinish(true)
            return
        end

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
                revision = Mod.WorldShare.Store:Get('world/currentRevision'),
                date = os.date('%Y%m%d', os.time())
            }

            local worldInfo = {}
            local username = self.currentWorld.user and self.currentWorld.user.username or Mod.WorldShare.Store:Get('user/username')
            local base32Foldername = GitEncoding.Base32(self.currentWorld.foldername or '')
            local repoPath = Mod.WorldShare.Utils.UrlEncode(username .. '/' .. base32Foldername)

            worldInfo.worldName = self.currentWorld.foldername
            worldInfo.revision = Mod.WorldShare.Store:Get('world/currentRevision')
            worldInfo.fileSize = filesTotals
            worldInfo.commitId = lastCommitSha
            worldInfo.archiveUrl = format('%s/repos/%s/archive.zip?ref=%s', KeepworkService:GetApiCdnApi(), repoPath, lastCommitSha)

            -- set world type
            local currentWorldTag = LocalService:GetTag(self.currentWorld.worldpath) or {}
            
            if currentWorldTag.world_generator and type(currentWorldTag.world_generator) == 'string' then
                if currentWorldTag.world_generator == 'paraworldMini' then
                    worldInfo.type = 1
                elseif currentWorldTag.world_generator == 'paraworld' then
                    worldInfo.type = 2
                else
                    worldInfo.type = 0
                end
            end

            local function AfterHandlePreview(preview)
                EventTrackingService:Send(1, 'click.world.after_upload', { blockCount = Mod.WorldShare.Store:Get('world/blockCount') or 0 })

                preview = preview or ''

                worldInfo.extra = {
                    coverUrl = preview,
                    commitIds = commitIds,
                    worldTagName = self.currentWorld.name,
                }

                KeepworkServiceWorld:PushWorld(
                    oldWorldInfo.id,
                    worldInfo,
                    function(data, err)
                        if err ~= 200 then
                            self.callback(false, L'更新服务器列表失败')
                            self:SetFinish(true)
                            return
                        end

                        KeepworkServiceProject:GetProject(
                            self.currentWorld.kpProjectId,
                            function(data)
                                local extra = {}
        
                                if Mod.WorldShare.Store:Get('world/isPreviewUpdated') then
                                    extra.imageUrl = preview
                                end
        
                                extra.worldTagName = self.currentWorld.name

                                -- 家园的话parentId传为-1
                                local parent_id = self.currentWorld.parentProjectId
                                if worldInfo and worldInfo.type == 1 then
                                    local folder_name = self.currentWorld.foldername or ''
                                    local _, end_index = string.find(folder_name, '_main')
                                    if end_index and end_index == #folder_name then
                                        parent_id = -1
                                    end
                                end

                                local params = {
                                    parentId = parent_id,
                                    extra = extra,
                                }

                                if currentWorldTag and type(currentWorldTag) == 'table' then
                                    params.fromProjects = currentWorldTag.fromProjects
                                    params.worldGenerator = currentWorldTag.world_generator
                                    params.tag = currentWorldTag
                                end

                                local setPrivateDuringSync = Mod.WorldShare.Store:Get('world/setPrivateDuringSync')

                                if setPrivateDuringSync then
                                    params.visibility = 1
                                    Mod.WorldShare.Store:Remove('world/setPrivateDuringSync')
                                end

                                KeepworkServiceProject:UpdateProject(
                                    self.currentWorld.kpProjectId,
                                    params
                                )

                                Mod.WorldShare.Store:Remove('world/isPreviewUpdated')
        
                                if not self.currentWorld.status then
                                    -- covert to online instance
                                    self.currentWorld = KeepworkServiceWorld:GenerateWorldInstance({
                                        text = self.currentWorld.text,
                                        foldername = self.currentWorld.foldername or '',
                                        revision = Mod.WorldShare.Store:Get('world/currentRevision'),
                                        size = filesTotals,
                                        modifyTime = os.time(),
                                        lastCommitId = self.currentWorld.lastCommitId, 
                                        worldpath = self.currentWorld.worldpath,
                                        status = 3,
                                        project = data.project,
                                        user = {
                                            id = data.userId,
                                            username = data.username,
                                        },
                                        kpProjectId = self.currentWorld.kpProjectId,
                                        fromProjectId = self.currentWorld.fromProjectId,
                                        parentProjectId = self.currentWorld.parentProjectId,
                                        name = self.currentWorld.name,
                                        IsFolder = true,
                                        is_zip = false,
                                        shared = self.currentWorld.shared,
                                        communityWorld = self.currentWorld.communityWorld,
                                        isVipWorld = self.currentWorld.isVipWorld,
                                        instituteVipEnabled = self.currentWorld.instituteVipEnabled,
                                        memberCount = data.memberCount,
                                        members = {}, -- updated at enter world
                                        level = data.level,
                                    })
                                end

                                Mod.WorldShare.Store:Set('world/currentWorld', self.currentWorld)

                                -- updated world mod data
                                KeepworkService:SetCurrentCommitId()

                                if callback and type(callback) == 'function' then
                                    callback()
                                end
                            end
                        )
                    end
                )

            end

            StorageFilesApi:Token(
                'preview.jpg',
                function(data, err)
                    if not data.token or not data.key then
                        AfterHandlePreview()
                        return false
                    end

                    local targetDir = format('%s/%s/preview.jpg', Mod.WorldShare.Utils.GetWorldFolderFullPath(), commonlib.Encoding.Utf8ToDefault(self.currentWorld.foldername))
                    local content = LocalService:GetFileContent(targetDir)

                    if not content then
                        AfterHandlePreview()
                        return false
                    end

                    if not self.currentWorld or
                    not self.currentWorld.kpProjectId or
                    self.currentWorld.kpProjectId == 0 or
                    not lastCommitSha then
                        return false
                    end

                    QiniuRootApi:Upload(
                        data.token,
                        data.key,
                        self.currentWorld.kpProjectId .. '-preview-' .. lastCommitSha .. '.jpg',
                        content,
                        function( _, err)
                            if err ~= 200 then
                                AfterHandlePreview()
                                return false
                            end

                            StorageFilesApi:List(data.key, function(listData, err)
                                if listData and type(listData.data) ~= 'table' then
                                    AfterHandlePreview()
                                    return false
                                end

                                for key, item in ipairs(listData.data) do
                                    if item.key == data.key then
                                        if item.downloadUrl then
                                            AfterHandlePreview(item.downloadUrl)
                                            return true
                                        end
                                    end
                                end
    
                                AfterHandlePreview()
                            end)
                        end
                    )
                end,
                function()
                    AfterHandlePreview()
                end
            )
        end

        local worldUserId = 0

        if self.currentWorld.shared then
            worldUserId = self.currentWorld.user.id
        end

        KeepworkServiceWorld:GetWorld(
            self.currentWorld.foldername,
            self.currentWorld.shared,
            worldUserId,
            HandleGetWorld
        )
    end

    GitService:GetCommits(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        Handle
    )
end