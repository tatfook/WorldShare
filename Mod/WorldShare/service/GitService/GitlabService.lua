--[[
Title: GitlabService
Author(s):  big
Date:  2017.4.15
Desc: 
use the lib:
------------------------------------------------------------
local GitlabService = NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua")
------------------------------------------------------------
]]
NPL.load("./FileDownloader/FileDownloader.lua")
local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")

local WorldShare = commonlib.gettable("Mod.WorldShare")
local Encoding = commonlib.gettable("commonlib.Encoding")

local UserConsole = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/Main.lua')
local SyncMain = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Main.lua')
local HttpRequest = NPL.load('./HttpRequest.lua')
local KeepworkService = NPL.load('./KeepworkService.lua')
local Store = NPL.load('(gl)Mod/WorldShare/store/Store.lua')
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')
local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")

local GitlabService = NPL.export()

function GitlabService:GetRawBaseUrl()
    return Config.dataSourceRawList.gitlab[KeepworkService:GetEnv()]
end

function GitlabService:GetDataSourceInfo()
    return Store:Get("user/dataSourceInfo")
end

function GitlabService:GetToken()
    local dataSourceInfo = self:GetDataSourceInfo()

    if (dataSourceInfo and dataSourceInfo.dataSourceToken) then
        return dataSourceInfo.dataSourceToken
    else
        return ''
    end
end

function GitlabService:GetApiBaseUrl()
    local dataSourceInfo = self:GetDataSourceInfo()

    if (dataSourceInfo and dataSourceInfo.apiBaseUrl) then
        return dataSourceInfo.apiBaseUrl
    else
        return ''
    end
end

function GitlabService:GetProjectPath(projectName)
    local dataSourceInfo = self:GetDataSourceInfo()
    local projectPath = Mod.WorldShare.Utils.UrlEncode(format("%s/%s", dataSourceInfo.dataSourceUsername or "", projectName or ""))

    return projectPath
end

function GitlabService:CheckSpecialCharacter(filename)
    local specialCharacter = {"【", "】", "《", "》", "·", " ", "，", "●"}

    for key, item in pairs(specialCharacter) do
        if (string.find(_filename, item)) then
            commonlib.TimerManager.SetTimeout(
                function()
                    _guihelper.MessageBox(format(L"%s文件包含了特殊字符或空格，请重命名文件，否则无法上传。", filename))
                end,
                500
            )

            return true
        end
    end

    return false
end

function GitlabService:ApiGet(url, callback)
    local apiBaseUrl = self:GetApiBaseUrl()
    local token = self:GetToken()

    if (not url or not apiBaseUrl) then
        return false
    end

    url = format("%s/%s", apiBaseUrl, url)

    HttpRequest:GetUrl(
        {
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = token,
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

function GitlabService:ApiPost(url, params, callback)
    local apiBaseUrl = self:GetApiBaseUrl()
    local token = self:GetToken()

    if (not url or not params) then
        return false
    end

    url = format("%s/%s", apiBaseUrl, url)

    HttpRequest:GetUrl(
        {
            method = "POST",
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = token,
                ["User-Agent"] = "npl"
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

function GitlabService:ApiPut(url, params, callback)
    if (not url or not params) then
        return false
    end

    local apiBaseUrl = self:GetApiBaseUrl()
    local token = self:GetToken()

    url = format("%s/%s", apiBaseUrl, url)

    HttpRequest:GetUrl(
        {
            method = "PUT",
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = token,
                ["User-Agent"] = "npl"
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

function GitlabService:ApiDelete(url, params, callback)
    local apiBaseUrl = self:GetApiBaseUrl()
    local token = self:GetToken()

    url = format("%s/%s", apiBaseUrl, url)

    HttpRequest:GetUrl(
        {
            method = "DELETE",
            url = url,
            json = true,
            headers = {
                ["PRIVATE-TOKEN"] = token,
                ["User-Agent"] = "npl"
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

function GitlabService:GetFileUrlPrefix(projectPath)
    if (not projectPath) then
        return false
    end

    return format("projects/%s/repository/files/", projectPath)
end

function GitlabService:GetCommitMessagePrefix()
    return "paracraft commit: "
end

-- get repository tree
function GitlabService:GetTree(projectName, commitId, callback)
    local projectPath = self:GetProjectPath(projectName or '')
    local url = format("projects/%s/repository/tree?recursive=true", projectPath)

    self.treeData = commonlib.Array:new()
    self.treePage = 1
    self.treePerPage = 100

    if type(commitId) == 'string' then
        url = format("%s&ref=%s", url, commitId)
    end

    self:GetTreeApi(
        url,
        function(data)
            if type(callback) ~= 'function' then
                return false
            end

            local blob = {}

            for key, value in ipairs(data) do
                if (value.type == "blob") then
                    blob[#blob + 1] = value
                end
            end

            callback(blob)
        end
    )
end

function GitlabService:GetTreeApi(url, callback)
    local pageUrl = format("%s&page=%s&per_page=%s", url, self.treePage, self.treePerPage)

    self:ApiGet(
        pageUrl,
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if err ~= 200 then
                callback(self.treeData)
                return false
            end

            if type(data) ~= 'table' or #data == 0 then
                callback(self.treeData)
                return false
            end

            self.treeData:AddAll(data)

            self.treePage = self.treePage + 1
            self:GetTreeApi(url, callback)
        end
    )
end

-- Create a gitlab repository
function GitlabService:Create(projectName, callback)
    local projectId

    self:ApiGet(
        "projects?owned=true&page=1&per_page=100",
        function(projectList, err)
            if (projectList) then
                for i = 1, #projectList do
                    if (projectList[i].name == projectName) then
                        projectId = projectList[i].id

                        if (type(callback) == "function") then
                            callback(projectId)
                        end

                        return false
                    end
                end

                local params = {
                    name = projectName,
                    visibility = "public",
                    request_access_enabled = true
                }

                self:ApiPost(
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

-- get repository commits
local commitsPerPage = 100

-- @param isGetAll: fetch all commits or we will only fetch head
-- @param callback: function(data, err) end
-- @param commits: this can be nil or an array for holding output
-- @param pageSize: pageSize default to 1 if isGetAll is false, or 100
-- @param commitPage: current page index, default to 1
function GitlabService:GetCommits(projectName, isGetAll, callback, commits, pageSize, commitPage)
    commits = commits or commonlib.vector:new()
    local projectPath = self:GetProjectPath(projectName or '')

    if(not pageSize) then
        pageSize = isGetAll and commitsPerPage or 1;
    end

    commitPage = commitPage or 1;
    local url = format("projects/%s/repository/commits?per_page=%s&page=%s", projectPath, pageSize, commitPage)

    self:ApiGet(
        url,
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if err ~= 200 then
                callback(commits, err)
                return false
            end

            if type(data) ~= 'table' or #data == 0 then
                callback(commits, err)
                commitPage = 1
                return false
            end

            commits:AddAll(data)

            if (isGetAll) then
                commitPage = commitPage + 1
                self:GetCommits(projectName, isGetAll, callback, commits, pageSize, commitPage)
            else
                callback(commits, err)
                return false
            end
        end
    )
end

-- write a file
function GitlabService:Upload(projectName, path, content, callback)
    local projectPath = self:GetProjectPath(projectName or '')
    local url = format("%s%s", self:GetFileUrlPrefix(projectPath), Mod.WorldShare.Utils.UrlEncode(path))

    local params = {
        commit_message = format("%s%s", GitlabService:GetCommitMessagePrefix(), path),
        branch = "master",
        content = content
    }

    self:ApiPost(
        url,
        params,
        function(data, err)
            if (err == 201) then
                if (type(callback) == "function") then
                    callback(true, path, data, err)
                end
            else
                self:Update(projectName, path, content, callback)
            end
        end
    )
end

-- Update a file
function GitlabService:Update(projectName, path, content, callback)
    local projectPath = self:GetProjectPath(projectName or '')
    local url = format("%s%s", self:GetFileUrlPrefix(projectPath), Mod.WorldShare.Utils.UrlEncode(path))

    local params = {
        commit_message = format("%s%s", GitlabService:GetCommitMessagePrefix(), path),
        branch = "master",
        content = content
    }

    self:ApiPut(
        url,
        params,
        function(data, err)
            if (err == 200) then
                if (type(callback) == "function") then
                    callback(true, path, data, err)
                end
            else
                if (type(callback) == "function") then
                    callback(false, path, data, err)
                end
            end
        end
    )
end

-- get a file content
function GitlabService:GetContent(projectName, path, commitId, callback)
    local projectPath = self:GetProjectPath(projectName or '')
    local url = format("%s%s?ref=%s", self:GetFileUrlPrefix(projectPath), path, commitId or 'master')

    self:ApiGet(
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

-- get a file content (with raw protocol)
function GitlabService:GetContentWithRaw(foldername, path, commitId, callback)
    local dataSourceInfo = self:GetDataSourceInfo()

    if (not commitId) then
        commitId = "master"
    end

    local url =
        format(
        "%s/%s/%s/raw/%s/%s",
        dataSourceInfo.rawBaseUrl,
        dataSourceInfo.dataSourceUsername,
        foldername,
        commitId,
        Mod.WorldShare.Utils.UrlEncode(path)
    )

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
                if (type(data) ~= 'string' or #data == 0) then
                    callback('', 0, err)
                else
                    callback(data, #data, err)
                end
            end
        end
    )
end

-- remove a file
function GitlabService:DeleteFile(projectName, path, callback)
    local projectPath = self:GetProjectPath(projectName or '')
    local url = format("%s%s", self:GetFileUrlPrefix(projectPath), Mod.WorldShare.Utils.UrlEncode(path))

    local params = {
        commit_message = format("%s%s", self:GetCommitMessagePrefix(), path),
        branch = "master"
    }

    self:ApiDelete(
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

-- download all files through zip package
function GitlabService:DownloadZIP(foldername, commitId, callback)
    if (not foldername or not commitId) then
        return false
    end

    local dataSourceInfo = self:GetDataSourceInfo()

    local url = format(
        "%s/%s/%s/repository/archive.zip?ref=%s",
        dataSourceInfo.rawBaseUrl,
        dataSourceInfo.dataSourceUsername,
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
        false
    )
end

-- delete a world repository
function GitlabService:DeleteResp(projectId, callback)
    if (not projectId) then
        return false
    end

    local url = format("projects/%s", projectId)
    self:ApiDelete(url, {}, callback)
end

function GitlabService:GetWorldRevision(projectId, isGetMine, callback)
    if type(callback) ~= "function" then
        return false
    end

    KeepworkService:GetProject(tonumber(projectId), function(data, err)
        if not data or not data.world or not data.world.worldName or not data.world.archiveUrl then
            callback()
            return false
        end

        if isGetMine and data.userId ~= Mod.WorldShare.Store:Get('user/userId') then
            callback()
            return false
        end

        local commitId = data.world and data.world.commitId or 'master'
        local rawBaseUrl = self:GetRawBaseUrl()
        local pattern = rawBaseUrl:gsub("%-", "%%%-")
        pattern = pattern .. "/([%w_]+)/"
        local gitlabUsername = string.match(data.world.archiveUrl, pattern)

        if not gitlabUsername then
            return false
        end

        local contentUrl =
            format(
                "%s/%s/%s/raw/%s/revision.xml",
                self:GetRawBaseUrl(),
                gitlabUsername,
                GitEncoding.Base32(data.world.worldName),
                commitId
            )

        HttpRequest:GetUrl(
            contentUrl,
            function(data, err)
                callback(tonumber(data) or 0, err)
            end,
            {0, 502}
        )
    end, {0})
end

function GitlabService:GetSingleProject(projectName, callback)
    local projectPath = self:GetProjectPath(projectName)

    local url = format("projects/%s", projectPath)

    self:ApiGet(
        url,
        function(data, err)
            if type(callback) == 'function' then
                callback(data, err)
            end
        end
    )
end

-- get projectId with projectName
function GitlabService:GetProjectIdByName(name, callback)
    self:ApiGet(
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

function GitlabService:GetCommitIdByFoldername(foldername)
    local remoteWorldsList = Store:Get("world/remoteWorldsList") or {}

    for key, value in ipairs(remoteWorldsList) do
        if (value.worldsName == foldername) then
            return value.commitId
        end
    end
end