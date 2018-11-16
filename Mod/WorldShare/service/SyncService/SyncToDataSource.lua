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
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
local Progress = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local KeepworkGen = NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local SyncToDataSource = NPL.export()

local UPDATE = "UPDATE"
local UPLOAD = "UPLOAD"
local DELETE = "DELETE"

function SyncToDataSource:Init()
    self.worldDir = Store:Get("world/worldDir")
    self.foldername = Store:Get("world/foldername")
    local selectWorld = Store:Get("world/selectWorld")

    if (not self.worldDir or not self.worldDir.default or self.worldDir.default == "") then
        _guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空")
        return false
    end

    -- 关闭进行中提示并加载进度UI界面
    MsgBox:Close()
    Progress:Init(self)

    self:SetFinish(false)
    self:SetBroke(false)

    self:IsProjectExist(
        function(beExisted)
            if beExisted then
                self:SyncToDataSource()
            else
                KeepworkService:CreateProject(
                    self.foldername.utf8,
                    function(data, err)
                        if err ~= 200 or not data or not data.id then
                            _guihelper.MessageBox(L"数据源创建失败")
                            Progress:ClosePage()
                            return false
                        end

                        selectWorld.kpProjectId = data.id

                        Store:Set("world/selectWorld", selectWorld)

                        self:SyncToDataSource()
                    end
                )
            end
        end
    )
end

function SyncToDataSource:IsProjectExist(callback)
    GitService:GetSingleProject(
        self.foldername.base32,
        function(data, err)
            if type(callback) ~= "function" then
                return false
            end

            if err == 200 then
                callback(true)    
            else
                callback(false)
            end
        end
    )
end

function SyncToDataSource:SyncToDataSource()
    self.compareListIndex = 1
    self.compareListTotal = 0

    Progress:UpdateDataBar(0, 0, L"正在对比文件列表...")

    local function Handle(data, err)
        self.dataSourceFiles = data
        self.localFiles = commonlib.vector:new()
        self.localFiles:AddAll(LocalService:LoadFiles(self.worldDir.default)) --再次获取本地文件，保证上传的内容为最新

        Store:Set('world/localFiles', self.localFiles)

        self:IgnoreFiles()
        self:CheckReadmeFile()
        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:GetTree(
        self.foldername.base32,
        nil, --commitId
        Handle
    )
end

function SyncToDataSource:IgnoreFiles()
    local fileList = {"mod/"}

    for LKey, LItem in ipairs(self.localFiles) do
        for FKey, FItem in ipairs(fileList) do
            if(string.find(LItem.filename, FItem)) then
                self.localFiles:remove(LKey)
            end
        end
    end
end

function SyncToDataSource:CheckReadmeFile()
    if (not self.localFiles) then
        return false
    end

    local hasReadme = false

    for key, value in ipairs(self.localFiles) do
        if (string.upper(value.filename) == "README.MD") then
            if (value.filename == "README.md") then
                hasReadme = true
            else
                LocalService:Delete(self.foldername.default, value.filename)
                hasReadme = false
            end
        end
    end

    if (not hasReadme) then
        local filePath = format("%sREADME.md", self.worldDir.default)
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
            if (LItem.filename == IItem.path) then
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
            if (IItem.path == LItem.filename) then
                bIsExisted = true
                break
            end
        end

        if (not bIsExisted) then
            local currentItem = {
                file = IItem.path,
                status = DELETE
            }

            self.compareList:push_back(currentItem)
        end
    end

    -- handle revision in last
    for CKey, CItem in ipairs(self.compareList) do
        if (string.lower(CItem.file) == "revision.xml") then
            self.compareList:push_back(CItem)
            self.compareList:remove(CKey)
        end
    end

    self.compareListTotal = #self.compareList
end

function SyncToDataSource:RefreshList()
    KeepworkService:UpdateRecord(
        function()
            Progress:SetFinish(true)
            Progress:Refresh()

            Store:Set(
                "world/CloseProcess",
                function()
                    WorldList:RefreshCurrentServerList(
                        function()
                            Store:Set("world/shareMode", false)
                        end
                    )
                end
            )
        end
    )
end

function SyncToDataSource:HandleCompareList()
    if (self.compareListTotal < self.compareListIndex) then
        -- sync finish
        self:SetFinish(true)
        self:RefreshList()

        self.compareListIndex = 1
        return false
    end

    if (self.broke) then
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

    if (currentItem.status == UPDATE) then
        self:UpdateOne(currentItem.file, Retry)
    end

    if (currentItem.status == UPLOAD) then
        self:UploadOne(currentItem.file, Retry)
    end

    if (currentItem.status == DELETE) then
        self:DeleteOne(currentItem.file, Retry)
    end
end

function SyncToDataSource:GetLocalFileByFilename(filename)
    for key, item in ipairs(self.localFiles) do
        if (item.filename == filename) then
            return item
        end
    end
end

function SyncToDataSource:GetRemoteFileByPath(path)
    for key, item in ipairs(self.dataSourceFiles) do
        if (item.path == path) then
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

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 上传中", currentLocalItem.filename, Utils.FormatFileSize(currentLocalItem.filesize, "KB"))
    )

    GitService:Upload(
        self.foldername.base32,
        currentLocalItem.filename,
        currentLocalItem.file_content_t,
        function(bIsUpload, filename, data)
            echo(data, true)
            if (bIsUpload) then
                if (type(callback) == "function") then
                    callback()
                end
            else
                _guihelper.MessageBox(format("%s上传失败", currentLocalItem.filename))
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
        format(L"%s （%s） 更新中", currentLocalItem.filename, Utils.FormatFileSize(currentLocalItem.filesize, "KB"))
    )

    if (currentLocalItem.sha1 == currentRemoteItem.id and currentLocalItem.filename ~= "revision.xml") then
        if (type(callback) == "function") then
            Utils.SetTimeOut(callback)
        end

        return false
    end

    GitService:Update(
        self.foldername.base32,
        currentLocalItem.filename,
        currentLocalItem.file_content_t,
        currentLocalItem.sha,
        function(bIsUpdate, filename)
            if (bIsUpdate) then
                if (type(callback) == "function") then
                    callback()
                end
            else
                _guihelper.MessageBox(L"更新失败")
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

    Progress:UpdateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s 删除中", currentRemoteItem.path)
    )

    GitService:DeleteFile(
        self.foldername.base32,
        currentRemoteItem.path,
        currentRemoteItem.sha,
        function(bIsDelete)
            if (bIsDelete) then
                if (type(callback) == "function") then
                    callback()
                end
            else
                _guihelper.MessageBox(L"删除失败")
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