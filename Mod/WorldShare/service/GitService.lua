--[[
Title: GitService
Author(s):  big
Date:  2018.6.20
Place: Foshan
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/store/Global.lua")

local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")

local GitService = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.service.GitService"))

local GITLAB = "GITLAB"
local GITHUB = "GITHUB"

function GitService:ctor()
    self.dataSourceInfo = GlobalStore.get("dataSourceInfo")
    self.dataSourceType = string.upper(self.dataSourceInfo.dataSourceType)
end

function GitService:create(foldername, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():create(foldername, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():create(foldername, callback)
    end
end

function GitService:getContent(projectId, foldername, path, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():getContent(foldername, path, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():getContent(projectId, path, callback)
    end
end

function GitService:getContentWithRaw(foldername, path, commitId, callback)
    if (self.dataSourceType == GITHUB) then
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():getContentWithRaw(foldername, path, commitId, callback)
    end
end

function GitService:upload(projectId, foldername, filename, content, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():upload(foldername, filename, content, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():upload(projectId, filename, content, callback)
    end
end

function GitService:update(projectId, foldername, filename, content, sha, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():update(foldername, filename, content, sha, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():update(projectId, filename, content, callback)
    end
end

function GitService:deleteFile(projectId, foldername, path, sha, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():deleteFile(foldername, path, sha, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():deleteFile(projectId, path, callback)
    end
end

function GitService:DownloadZIP(foldername, commitId, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():DownloadZIP(foldername, commitId, callback)
    elseif(self.dataSourceType == GITLAB) then
        GitlabService:new():DownloadZIP(foldername, commitId, callback)
    end
end

function GitService:getTree(projectId, foldername, commitId, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():getTree(foldername, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():getTree(projectId, commitId, callback)
    end
end

function GitService:getCommits(projectId, foldername, IsGetAll, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():getCommits(foldername, IsGetAll, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():getCommits(projectId, IsGetAll, callback)
    end
end

function GitService:getWorldRevision(foldername, callback)
    if (self.dataSourceType == GITHUB) then
        GithubService:new():getWorldRevision(foldername, callback)
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():getWorldRevision(foldername, callback)
    end
end

function GitService:getProjectIdByName(name, callback)
    GitlabService:new():getProjectIdByName(name, callback)
end

function GitService:deleteResp(projectId, foldername, callback)
    if (self.dataSourceType == GITHUB) then
    elseif (self.dataSourceType == GITLAB) then
        GitlabService:new():deleteResp(projectId, callback)
    end
end
