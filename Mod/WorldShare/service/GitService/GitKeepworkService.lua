--[[
Title: GitlabService
Author(s):  big
CreateDate: 2019.12.10
UpdateDate: 2021.08.05
Desc: 
use the lib:
------------------------------------------------------------
local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')
------------------------------------------------------------
]]

-- api
local KeepworkReposApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Repos.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Projects.lua')

-- service
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')

-- config
local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')

local GitKeepworkService = NPL.export()

function GitKeepworkService:GetQiNiuArchiveUrl(foldername, username, commitId)
    if System.os.IsWindowsXP() then
        return self:GetCdnArchiveUrl(foldername, username, commitId)
    else
        return format(
                    '%s/%s-%s.zip',
                    Config:GetValue('qiniuGitZip'),
                    GitService:GetRepoPath(foldername, username),
                    commitId
                )
    end
end

function GitKeepworkService:GetCdnArchiveUrl(foldername, username, commitId)
    local baseUrl = ''

    if System.os.IsWindowsXP() then
        baseUrl = Config:GetValue('xpGitZip')
    else
        baseUrl = Config:GetValue('keepworkApiCdnList')
    end

    return format(
            '%s/repos/%s/download?ref=%s',
            baseUrl,
            GitService:GetRepoPath(foldername, username),
            commitId
           )
end

function GitKeepworkService:GetContentWithRaw(foldername, username, path, commitId, callback, cdnState)
    KeepworkReposApi:Raw(
        foldername,
        username,
        path,
        commitId,
        function(data, err)
            if type(callback) == 'function' then
                callback(data, err)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end,
        cdnState
    )
end

function GitKeepworkService:Upload(foldername, username, path, content, callback)
    KeepworkReposApi:CreateFile(
        foldername,
        username,
        path,
        content,
        function()
            if type(callback) == 'function' then
                callback(true)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function GitKeepworkService:Update(foldername, username, path, content, callback)
    KeepworkReposApi:UpdateFile(
        foldername,
        username,
        path,
        content,
        function()
            if type(callback) == 'function' then
                callback(true)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function GitKeepworkService:DeleteFile(foldername, username, path, callback)
    KeepworkReposApi:RemoveFile(
        foldername,
        username,
        path,
        function()
            if type(callback) == 'function' then
                callback(true)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function GitKeepworkService:DownloadZIP(foldername, username, commitId, callback)
    KeepworkReposApi:Download(foldername, username, commitId, callback, callback)
end

local recursiveData = {}
function GitKeepworkService:GetTree(foldername, username, commitId, callback)
    KeepworkReposApi:Tree(foldername, username, commitId, function(data, err)
        if type(data) ~= 'table' then
            return false
        end

        local _data = {}

        for key, item in ipairs(data) do
            if item.isBlob then
                _data[#_data + 1] = item
            end

            if item.isTree and item.children then
                recursiveData = {}
                self:GetRecursive(item.children)

                for RKey, RItem in ipairs(recursiveData) do
                    if RItem.isBlob then
                        _data[#_data + 1] = RItem
                    end
                end

                recursiveData = {}
            end
        end

        if type(callback) == 'function' then
            callback(_data, err)
        end
    end, callback)
end

function GitKeepworkService:GetRecursive(children)
    if type(children) ~= 'table' then
        return false
    end

    for key, item in ipairs(children) do
        if item.isBlob then
            recursiveData[#recursiveData + 1] = item
        end

        if item.isTree and item.children then
            self:GetRecursive(item.children)
        end
    end
end

function GitKeepworkService:GetCommits(foldername, username, callback)
    KeepworkReposApi:CommitInfo(foldername, username, callback)
end

function GitKeepworkService:GetWorldRevision(kpProjectId, isGetMine, callback)
    KeepworkProjectsApi:GetProject(
        kpProjectId,
        function(data, err)
            if isGetMine then
                if type(data) ~= 'table' or not data.id or tonumber(data.id) ~= tonumber(kpProjectId) then
                    if type(callback) == 'function' then
                        callback()
                    end
                    return false
                end
            end

            if type(data) ~= 'table' or not data.username or not data.name or not data.world then
                return false
            end

            KeepworkReposApi:Raw(
                data.name,
                data.username,
                'revision.xml',
                data.world.commitId,
                function(data, err)
                    if type(callback) == 'function' then
                        callback(tonumber(data) or 0, err)
                    end
                end,
                function()
                    if type(callback) == 'function' then
                        callback(0, err)
                    end
                end
            )
        end,
        function(_, err)
            callback(0, err)
        end
    )
end


