--[[
Title: GitService
Author(s): big
CreateDate: 2018.06.20
UpdateDate: 2021.08.05
Place: Foshan
use the lib:
------------------------------------------------------------
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
------------------------------------------------------------
]]

-- service
local GitKeepworkService = NPL.load('./GitService/GitKeepworkService.lua')

-- helper
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

local GitService = NPL.export()

local KEEPWORK = 'KEEPWORK'

function GitService:GetDataSourceInfo()
    return Mod.WorldShare.Store:Get("user/dataSourceInfo")
end

function GitService:GetDataSourceType()
    return KEEPWORK
end

function GitService:GetRepoPath(foldername, username)
    username = username or Mod.WorldShare.Store:Get('user/username')

    if type(username) ~= 'string' or type(foldername) ~= 'string' then
        return ''
    else
        return Mod.WorldShare.Utils.UrlEncode(username .. '/' .. GitEncoding.Base32(foldername))
    end
end

function GitService:Create(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:Create(...)
    end
end

function GitService:GetContent(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:GetContent(...)
    end
end

function GitService:GetContentWithRaw(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:GetContentWithRaw(...)
    end
end

function GitService:Upload(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:Upload(...)
    end
end

function GitService:Update(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:Update(...)
    end
end

function GitService:DeleteFile(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:DeleteFile(...)
    end
end

function GitService:DownloadZIP(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:DownloadZIP(...)
    end
end

function GitService:GetTree(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:GetTree(...)
    end
end

function GitService:GetCommits(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:GetCommits(...)
    end
end

function GitService:GetWorldRevision(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:GetWorldRevision(...)
    end
end

function GitService:GetProjectIdByName(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:GetProjectIdByName(...)
    end
end

function GitService:DeleteResp(...)
    if self:GetDataSourceType() == KEEPWORK then
        GitKeepworkService:DeleteResp(...)
    end
end