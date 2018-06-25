--[[
Title: GitlabService
Author(s):  big
Date:  2017.4.15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua")
local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
NPL.load("(gl)Mod/WorldShare/main.lua")
NPL.load("(gl)script/ide/Encoding.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")

local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest")
local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local WorldShare = commonlib.gettable("Mod.WorldShare")
local Encoding = commonlib.gettable("commonlib.Encoding")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader")

local GitlabService = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.service.GitlabService"))

GitlabService.inited = false
GitlabService.tree = {}
GitlabService.newTree = {}
GitlabService.blob = {}
GitlabService.getTreePage = 1
GitlabService.getTreePer_page = 100

function GitlabService:ctor(projectId)
    self.dataSourceInfo = GlobalStore.get("dataSourceInfo")

    self.dataSourceToken = self.dataSourceInfo.dataSourceToken
    self.apiBaseUrl = self.dataSourceInfo.apiBaseUrl
    self.projectId = projectId
end

function GitlabService:checkSpecialCharacter(filename)
    local specialCharacter = {"【", "】", "《", "》", "·", " ", "，", "●"}

    for key, item in pairs(specialCharacter) do
        if (string.find(_filename, item)) then
            commonlib.TimerManager.SetTimeout(
                function()
                    _guihelper.MessageBox(format(L "%s文件包含了特殊字符或空格，请重命名文件，否则无法上传。", filename))
                end,
                500
            )

            return true
        end
    end

    return false
end

function GitlabService:apiGet(url, callback)
    if (not url or not self.apiBaseUrl) then
        return false
    end

    url = format("%s/%s", self.apiBaseUrl, url)

    HttpRequest:GetUrl(
        {
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = self.dataSourceToken,
                ["User-Agent"] = "npl"
            }
        },
        function(data, err)
            if (type(callback) == "function") then
                callback(data, err)
            end
        end
    )
end

function GitlabService:apiPost(url, params, callback)
    if (not url or not params) then
        return false
    end

    url = format("%s/%s", self.apiBaseUrl, url)

    HttpRequest:GetUrl(
        {
            method = "POST",
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = self.dataSourceToken,
                ["User-Agent"] = "npl",
                ["content-type"] = "application/json"
            },
            form = params
        },
        function(data, err)
            if (type(callback) == "function") then
                callback(data, err)
            end
        end
    )
end

function GitlabService:apiPut(url, params, callback)
    if (not url or not params) then
        return false
    end

    url = format("%s/%s", self.apiBaseUrl, url)

    HttpRequest:GetUrl(
        {
            method = "PUT",
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = self.dataSourceToken,
                ["User-Agent"] = "npl",
                ["content-type"] = "application/json"
            },
            form = params
        },
        function(data, err)
            if (type(callback) == "function") then
                callback(data, err)
            end
        end
    )
end

function GitlabService:apiDelete(url, params, callback)
    url = self.apiBaseUrl .. "/" .. url

    HttpRequest:GetUrl(
        {
            method = "DELETE",
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = self.dataSourceToken,
                ["User-Agent"] = "npl",
                ["content-type"] = "application/json"
            },
            form = params
        },
        function(data, err)
            if (type(callback) == "function") then
                callback(data, err)
            end
        end
    )
end

function GitlabService:getFileUrlPrefix(projectId)
    if (not projectId) then
        return false
    end

    return format("projects/%s/repository/files/", projectId)
end

function GitlabService:getCommitMessagePrefix()
    return "keepwork commit: "
end

-- 获得文件列表
function GitlabService:getTree(projectId, commitId, callback)
    local that = self
    local url = format("projects/%s/repository/tree?", projectId)

    that.blob = {}
    that.tree = {}

    if (commitId) then
        url = format("%sref=%s", url, commitId)
    end

    local fetchTimes = 0
    local function getSubTree()
        if (#that.tree ~= 0) then
            for key, value in ipairs(that.tree) do
                that:getSubTree(
                    function(subTree, subFolderName, commitId, projectId)
                        for checkKey, checkValue in ipairs(that.tree) do
                            if (checkValue.path == subFolderName) then
                                if (not checkValue.alreadyGet) then
                                    checkValue.alreadyGet = true
                                else
                                    return
                                end
                            end
                        end

                        fetchTimes = fetchTimes + 1

                        for subKey, subValue in ipairs(subTree) do
                            that.newTree[#that.newTree + 1] = subValue
                        end

                        if (#that.tree == fetchTimes) then
                            fetchTimes = 0
                            that.tree = commonlib.copy(that.newTree)
                            that.newTree = {}

                            getSubTree()
                        end
                    end,
                    value.path,
                    commitId,
                    projectId
                )
            end
        elseif (#that.tree == 0) then
            for cbKey, cbValue in ipairs(that.blob) do
                cbValue.sha = cbValue.id
            end

            if (type(callback) == "function") then
                callback(that.blob, 200)
            end
        end
    end

    that:getTreeApi(
        url,
        function(data, err)
            if (err == 404) then
                if (type(callback) == "function") then
                    callback({})
                end
            else
                if (type(data) == "table") then
                    for key, value in ipairs(data) do
                        if (value.type == "tree") then
                            that.tree[#that.tree + 1] = value
                        end

                        if (value.type == "blob") then
                            that.blob[#that.blob + 1] = value
                        end
                    end

                    getSubTree()
                else
                    _guihelper.MessageBox(L "获取sha文件失败")
                end
            end
        end
    )
end

function GitlabService:getSubTree(callback, path, commitId, projectId)
    local url = format("projects/%s/repository/tree?path=%s", projectId, path)

    if (commitId) then
        url = format("%s&ref=%s", url, commitId)
    end

    local tree = {}
    self:getTreeApi(
        url,
        function(data, err)
            for key, value in ipairs(data) do
                if (value.type == "tree") then
                    tree[#tree + 1] = value
                end

                if (value.type == "blob") then
                    self.blob[#self.blob + 1] = value
                end
            end

            if (type(callback) == "function") then
                callback(tree, path, commitId, projectId)
            end
        end
    )
end

function GitlabService:getTreeApi(url, callback)
    local url = format("%s&page=%s&per_page=%s", url, self.getTreePage, self.getTreePer_page)

    self:apiGet(
        url,
        function(data, err)
            if (#data == 0) then
                self.getTreePage = 1

                if (self.tmpTree) then
                    if (type(callback) == "function") then
                        callback(self.tmpTree, err)
                    end
                else
                    if (type(callback) == "function") then
                        callback(data, err)
                    end
                end

                self.tmpTree = nil
            else
                if (self.tmpTree) then
                    for _, value in ipairs(data) do
                        self.tmpTree[#self.tmpTree + 1] = value
                    end
                else
                    self.tmpTree = data
                end

                self.getTreePage = self.getTreePage + 1
                self:getTreeApi(url, callback)
            end
        end
    )
end

-- 初始化
function GitlabService:create(foldername, callback)
    local projectId

    self:apiGet(
        "projects?owned=true&page=1&per_page=100",
        function(projectList, err)
            if (projectList) then
                for i = 1, #projectList do
                    if (projectList[i].name == foldername) then
                        projectId = projectList[i].id

                        if (type(callback) == "function") then
                            callback(projectId)
                        end

                        return false
                    end
                end

                local params = {
                    name = foldername,
                    visibility = "public",
                    request_access_enabled = true
                }

                self:apiPost(
                    "projects",
                    params,
                    function(data, err)
                        if (data.id ~= nil) then
                            projectId = data.id

                            if (type(callback) == "function") then
                                callback(projectId)
                            end

                            return false
                        end
                    end
                )
            else
                if (type(callback) == "function") then
                    callback()
                end
            end
        end
    )
end

-- commit
function GitlabService:getCommits(projectId, callback)
    local url = format("projects/%s/repository/commits", projectId)
    self:apiGet(url, callback)
end

-- 写文件
function GitlabService:upload(projectId, filename, content, callback)
    if (not projectId or not filename or not content) then
        return false
    end

    local url = format("%s%s", self:getFileUrlPrefix(projectId), Encoding.url_encode(filename))

    local params = {
        commit_message = format("%s%s", GitlabService:getCommitMessagePrefix(), filename),
        branch = "master",
        content = content
    }

    self:apiPost(
        url,
        params,
        function(data, err)
            if (err == 201) then
                if (type(callback) == "function") then
                    callback(true, filename, data, err)
                end
            else
                self:update(projectId, filename, content, callback)
            end
        end
    )
end

--更新文件
function GitlabService:update(projectId, filename, content, callback)
    if (not projectId or not filename or not content) then
        return false
    end

    local url = format("%s%s", self:getFileUrlPrefix(projectId), Encoding.url_encode(filename))

    local params = {
        commit_message = format("%s%s", GitlabService:getCommitMessagePrefix(), filename),
        branch = "master",
        content = content
    }

    self:apiPut(
        url,
        params,
        function(data, err)
            if (err == 200) then
                if (type(callback) == "function") then
                    callback(true, filename, data, err)
                end
            else
                if (type(callback) == "function") then
                    callback(false, filename, data, err)
                end
            end
        end
    )
end

-- 获取文件
function GitlabService:getContent(projectId, path, callback)
    if (not projectId or not path) then
        return false
    end

    local url = format("%s%s?ref=master", self:getFileUrlPrefix(projectId), path)

    self:apiGet(
        url,
        function(data, err)
            if (err == 200 and data) then
                if (type(callback) == "function") then
                    callback(Encoding.unbase64(data.content), data.size, err)
                end
            else
                if (type(callback) == "function") then
                    callback(false)
                end
            end
        end
    )
end

-- 获取文件
function GitlabService:getContentWithRaw(foldername, path, callback)
    local foldername = GitEncoding.base32(foldername)
    local dataSourceInfo = GlobalStore.get("dataSourceInfo")

    local url =
        format("%s/%s/%s/raw/master/%s", dataSourceInfo.rawBaseUrl, dataSourceInfo.dataSourceUsername, foldername, path)

    HttpRequest:GetUrl(
        {
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = dataSourceInfo.dataSourceToken,
                ["User-Agent"] = "npl"
            }
        },
        function(data, err)
            if (err == 200 and type(callback) == "function") then
                callback(data, #data, err)
            end
        end
    )
end

function GitlabService:DownloadZIP(foldername, commitId, callback)
    if (not foldername or not commitId) then
        return false
    end

    local url =
        format(
        "%s/%s/%s/repository/archive.zip?ref=%s",
        self.dataSourceInfo.rawBaseUrl,
        self.dataSourceInfo.dataSourceUsername,
        foldername,
        commitId and commitId or "master"
    )

    LOG.std("GitlabService", "debug", "DZIP", "url: %s", url)

    FileDownloader:new():Init(
        nil,
        url,
        "temp/archive.zip",
        function(bSuccess, downloadPath)           
            if (type(callback) == "function") then
                callback(bSuccess, downloadPath)
            end
        end,
        "access plus 5 mins",
        true
    )
end

-- 删除文件
function GitlabService:deleteFile(projectId, path, callback)
    if (not projectId) then
        return false
    end

    local url = format("%s%s", self:getFileUrlPrefix(projectId), path)

    local params = {
        commit_message = format("%s%s", self:getCommitMessagePrefix(), path),
        branch = "master"
    }

    self:apiDelete(
        url,
        params,
        function(data, err)
            if (err == 204) then
                if (type(callback) == "function") then
                    callback(true)
                end
            else
                if (type(callback) == "function") then
                    callback(false)
                end
            end
        end
    )
end

--删除仓
function GitlabService:deleteResp(projectId, callback)
    if (not projectId) then
        return false
    end

    local url = format("projects/%s", projectId)
    self:apiDelete(url, {}, callback)
end

function GitlabService:getWorldRevision(foldername, callback)
    if (type(foldername) == "function") then
        return false
    end

    local contentUrl = ""
    local commitId = self:getCommitIdByFoldername(foldername.utf8)

    if (commitId) then
        contentUrl =
            format(
            "%s/%s/%s/raw/%s/revision.xml",
            self.dataSourceInfo.rawBaseUrl,
            self.dataSourceInfo.dataSourceUsername,
            foldername.base32,
            commitId
        )
    else
        contentUrl =
            format(
            "%s/%s/%s/raw/master/revision.xml",
            self.dataSourceInfo.rawBaseUrl,
            self.dataSourceInfo.dataSourceUsername,
            foldername.base32
        )
    end

    HttpRequest:GetUrl(
        contentUrl,
        function(data, err)
            callback(tonumber(data) or 0)
        end,
        {0, 502}
    )
end

--通过仓名获取仓ID
function GitlabService:getProjectIdByName(name, callback)
    self:apiGet(
        "projects?owned=true&page=1&per_page=100",
        function(projectList, err)
            for i = 1, #projectList do
                if (string.lower(projectList[i].name) == string.lower(name)) then
                    if (type(callback) == "function") then
                        callback(projectList[i].id)
                    end

                    return
                end
            end

            if (type(callback) == "function") then
                callback(false)
            end
        end
    )
end

function GitlabService:getCommitIdByFoldername(foldername)
    local remoteWorldsList = GlobalStore.get("remoteWorldsList") or {}

    for key, value in ipairs(remoteWorldsList) do
        if (value.worldsName == foldername) then
            return value.commitId
        end
    end
end
