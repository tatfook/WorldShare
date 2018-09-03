--[[
Title: GitService
Author(s):  big
Date:  2018.6.20
Place: Foshan
use the lib:
------------------------------------------------------------
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
------------------------------------------------------------
]]
local Store = NPL.load('(gl)Mod/WorldShare/store/Store.lua')

local GitlabService = NPL.load('./GitlabService.lua')
local GithubService = NPL.load('./GithubService.lua')

local GitService = NPL.export()

local GITLAB = "GITLAB"
local GITHUB = "GITHUB"

function GitService:getDataSourceInfo()
    return Store:get("user/dataSourceInfo")
end

function GitService:getDataSourceType()
    local dataSourceInfo = self:getDataSourceInfo()

    if (dataSourceInfo and dataSourceInfo.dataSourceType) then
        return string.upper(dataSourceInfo.dataSourceType)
    end
end

function GitService:create(foldername, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:create(foldername, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:create(foldername, callback)
    end
end

function GitService:getContent(projectId, foldername, path, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:getContent(foldername, path, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:getContent(projectId, path, callback)
    end
end

function GitService:getContentWithRaw(foldername, path, commitId, callback)
    if (self:getDataSourceType() == GITHUB) then
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:getContentWithRaw(foldername, path, commitId, callback)
    end
end

function GitService:upload(projectId, foldername, filename, content, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:upload(foldername, filename, content, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:upload(projectId, filename, content, callback)
    end
end

function GitService:update(projectId, foldername, filename, content, sha, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:update(foldername, filename, content, sha, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:update(projectId, filename, content, callback)
    end
end

function GitService:deleteFile(projectId, foldername, path, sha, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:deleteFile(foldername, path, sha, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:deleteFile(projectId, path, callback)
    end
end

function GitService:DownloadZIP(foldername, commitId, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:DownloadZIP(foldername, commitId, callback)
    elseif(self:getDataSourceType() == GITLAB) then
        GitlabService:DownloadZIP(foldername, commitId, callback)
    end
end

function GitService:getTree(projectId, foldername, commitId, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:getTree(foldername, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:getTree(projectId, commitId, callback)
    end
end

function GitService:getCommits(projectId, foldername, IsGetAll, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:getCommits(foldername, IsGetAll, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:getCommits(projectId, IsGetAll, callback)
    end
end

function GitService:getWorldRevision(foldername, callback)
    if (self:getDataSourceType() == GITHUB) then
        GithubService:getWorldRevision(foldername, callback)
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:getWorldRevision(foldername, callback)
    end
end

function GitService:getProjectIdByName(name, callback)
    GitlabService:getProjectIdByName(name, callback)
end

function GitService:deleteResp(projectId, foldername, callback)
    if (self:getDataSourceType() == GITHUB) then
    elseif (self:getDataSourceType() == GITLAB) then
        GitlabService:deleteResp(projectId, callback)
    end
end