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

function GitService:GetDataSourceInfo()
    return Store:Get("user/dataSourceInfo")
end

function GitService:GetDataSourceType()
    local dataSourceInfo = self:GetDataSourceInfo()

    if (dataSourceInfo and dataSourceInfo.dataSourceType) then
        return string.upper(dataSourceInfo.dataSourceType)
    end
end

function GitService:GetSingleProject(...)
    if (self:GetDataSourceType() == GITHUB) then

    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:GetSingleProject(...)
    end
end

function GitService:Create(...)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:create(foldername, callback)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:Create(...)
    end
end

function GitService:GetContent(...)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:getContent(...)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:GetContent(...)
    end
end

function GitService:GetContentWithRaw(...)
    if (self:GetDataSourceType() == GITHUB) then
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:GetContentWithRaw(...)
    end
end

function GitService:Upload(...)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:upload(projectName, filename, content, callback)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:Upload(...)
    end
end

function GitService:Update(projectName, path, content, sha, callback)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:update(projectName, filename, content, sha, callback)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:Update(projectName, path, content, callback)
    end
end

function GitService:DeleteFile(projectName, path, sha, callback)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:deleteFile(projectName, path, sha, callback)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:DeleteFile(projectName, path, callback)
    end
end

function GitService:DownloadZIP(...)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:downloadZIP(...)
    elseif(self:GetDataSourceType() == GITLAB) then
        GitlabService:DownloadZIP(...)
    end
end

function GitService:GetTree(...)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:getTree(...)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:GetTree(...)
    end
end

function GitService:GetCommits(...)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:GetCommits(...)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:GetCommits(...)
    end
end

function GitService:GetWorldRevision(...)
    if (self:GetDataSourceType() == GITHUB) then
        -- GithubService:GetWorldRevision(projectName, callback)
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:GetWorldRevision(...)
    end
end

function GitService:GetProjectIdByName(...)
    GitlabService:GetProjectIdByName(...)
end

function GitService:DeleteResp(...)
    if (self:GetDataSourceType() == GITHUB) then
    elseif (self:GetDataSourceType() == GITLAB) then
        GitlabService:DeleteResp(...)
    end
end