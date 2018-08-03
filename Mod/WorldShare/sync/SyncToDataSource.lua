--[[
Title: SyncToDataSource
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncToDataSource.lua")
local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")
NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua")

local SyncGUI = commonlib.gettable("Mod.WorldShare.sync.SyncGUI")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local KeepworkGen = commonlib.gettable("Mod.WorldShare.helper.KeepworkGen")

local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource")

local UPDATE = "UPDATE"
local UPLOAD = "UPLOAD"
local DELETE = "DELETE"

function SyncToDataSource:init()
    self.worldDir = GlobalStore.get("worldDir")
    self.foldername = GlobalStore.get("foldername")
    local selectWorld = GlobalStore.get("selectWorld")

    if (SyncMain:checkWorldSize()) then
        return false
    end

    if (not self.worldDir or not self.worldDir.default or self.worldDir.default == "") then
        _guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空")
        return false
    end

    -- 加载进度UI界面
    SyncGUI.init()
    SyncGUI.SetSync(self)

    self:SetFinish(false)
    self:SetBroke(false)

    GitService:new():create(
        self.foldername.base32,
        function(projectId)
            if (not projectId) then
                _guihelper.MessageBox(L"数据源创建失败")
                SyncGUI.closeWindow()
                return false
            end

            self.projectId = projectId
            selectWorld.projectId = projectId
            GlobalStore.set("selectWorld", selectWorld)

            self:syncToDataSource()
        end
    )
end

function SyncToDataSource:syncToDataSource()
    self.compareListIndex = 1
    self.compareListTotal = 0

    SyncGUI:updateDataBar(0, 0, L"正在对比文件列表...")

    local function handleSyncToDataSource(data, err)
        self.dataSourceFiles = data
        self.localFiles = commonlib.vector:new()
        self.localFiles:AddAll(LocalService:new():LoadFiles(self.worldDir.default)) --再次获取本地文件，保证上传的内容为最新

        GlobalStore.set('localFiles', self.localFiles)
        
        self:IgnoreFiles()
        self:CheckReadmeFile()
        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:new():getTree(
        self.projectId, --projectId
        self.foldername.base32,
        nil, --commitId
        handleSyncToDataSource
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
                LocalService:new():delete(self.foldername, value.filename)
                hasReadme = false
            end
        end
    end

    if (not hasReadme) then
        local filePath = format("%sREADME.md", self.worldDir.default)
        local file = ParaIO.open(filePath, "w")
        local content = KeepworkGen.readmeDefault

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
    SyncMain:RefreshKeepworkList(
        function()
            LoginWorldList.RefreshCurrentServerList(
                function()
                    GlobalStore.set("ShareMode", false)
                    SyncGUI.SetFinish(true)
                    SyncGUI:refresh()
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

    local function retry()
        SyncGUI:updateDataBar(
            self.compareListIndex,
            self.compareListTotal,
            format(L"%s 处理完成", currentItem.file),
            self.finish
        )

        self.compareListIndex = self.compareListIndex + 1
        self:HandleCompareList()
    end

    if (currentItem.status == UPDATE) then
        self:updateOne(currentItem.file, retry)
    end

    if (currentItem.status == UPLOAD) then
        self:uploadOne(currentItem.file, retry)
    end

    if (currentItem.status == DELETE) then
        self:deleteOne(currentItem.file, retry)
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
function SyncToDataSource:uploadOne(file, callback)
    local currentItem = self:GetLocalFileByFilename(file)

    SyncGUI:updateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 上传中", currentItem.filename, Utils.formatFileSize(currentItem.filesize, "KB"))
    )

    GitService:new():upload(
        self.projectId,
        nil,
        currentItem.filename,
        currentItem.file_content_t,
        function(bIsUpload, filename)
            if (bIsUpload) then
                if (type(callback) == "function") then
                    callback()
                end
            else
                _guihelper.MessageBox(format("%s上传失败", currentItem.filename))
                self:SetBroke(true)

                SyncGUI:updateDataBar(
                    self.compareListIndex,
                    self.compareListTotal,
                    format(L"%s 上传失败", currentItem.filename)
                )
            end
        end
    )
end

-- 更新数据源文件
function SyncToDataSource:updateOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    SyncGUI:updateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s （%s） 更新中", currentLocalItem.filename, Utils.formatFileSize(currentLocalItem.filesize, "KB"))
    )

    if (currentLocalItem.sha1 == currentRemoteItem.sha and currentLocalItem.filename ~= "revision.xml") then
        if (type(callback) == "function") then
            Utils.SetTimeOut(callback)
        end

        return false
    end

    GitService:new():update(
        self.projectId,
        nil,
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

                SyncGUI:updateDataBar(
                    self.compareListIndex,
                    self.compareListTotal,
                    format(L"%s 更新失败", currentItem.filename)
                )
            end
        end
    )
end

-- 删除数据源文件
function SyncToDataSource:deleteOne(file, callback)
    local currentItem = self:GetRemoteFileByPath(file)

    SyncGUI:updateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L"%s 删除中", currentItem.path)
    )

    GitService:new():deleteFile(
        self.projectId,
        nil,
        currentItem.path,
        currentItem.sha,
        function(bIsDelete)
            if (bIsDelete) then
                if (type(callback) == "function") then
                    callback()
                end
            else
                _guihelper.MessageBox(L"删除失败")
                self:SetBroke(true)

                SyncGUI:updateDataBar(
                    self.compareListIndex,
                    self.compareListTotal,
                    format(L"%s 删除失败", currentItem.filename)
                )
            end
        end
    )
end
