--[[
Title: Keepwork Repos API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkReposApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Repos.lua")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/service/FileDownloader/FileDownloader.lua")
local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")

local KeepworkBaseApi = NPL.load('./BaseApi.lua')
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')
local Encoding = commonlib.gettable("System.Encoding")

local KeepworkReposApi = NPL.export()

function KeepworkReposApi:GetRepoPath(foldername)
    local username = Mod.WorldShare.Store:Get('user/username')

    if type(username) ~= 'string' or type(foldername) ~= 'string' then
        return ''
    else
        return Mod.WorldShare.Utils.UrlEncode(username .. '/' .. GitEncoding.Base32(foldername))
    end
end

-- url: /repos/:repoPath/download
-- method: GET
-- params:
--[[
    repoPath string 必须 仓库路径	
    ref string 必须 ref
]]
-- return: object
function KeepworkReposApi:Download(foldername, commitId, success, error)
    local url = format('%s/repos/%s/download?ref=%s', KeepworkBaseApi:GetApi(), self:GetRepoPath(foldername), commitId)

    FileDownloader:new():Init(
        foldername,
        url,
        "temp/archive.zip",
        function(bSuccess, downloadPath)
            if bSuccess then
                if type(success) == "function" then
                    success(true, downloadPath)
                end
            else
                if type(error) == "function" then
                    error(false)
                end
            end

        end,
        "access plus 5 mins",
        false
    ) 
end

-- url: /repos/:repoPath/tree
-- method: GET
-- params:
--[[
    repoPath string 必须 仓库路径
    recursive string 选填 是否递归获取文件
    ref string 必须 commitId
]]
-- return: object
function KeepworkReposApi:Tree(foldername, commitId, success, error)
    local url = ''

    if type(foldername) ~= 'string' or type(commitId) ~= 'string' or commitId == 'master' then
        url = format('/repos/%s/tree?recursive=true', self:GetRepoPath(foldername))
    else
        url = format('/repos/%s/tree?recursive=true&commitId=%s', self:GetRepoPath(foldername), commitId)
    end

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /repos/:repoPath/commitInfo
-- method: GET
-- params: [[]]
-- return: object
function KeepworkReposApi:CommitInfo(foldername, success, error)
    if type(foldername) ~= 'string' then
        return false
    end

    local url = format('/repos/%s/commitInfo', self:GetRepoPath(foldername))

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /repos/:repoPath/files/:filePath/info
-- method: GET
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:Info()
end

-- url: /repos/:repoPath/files/:filePath/raw
-- method: GET
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:Raw(foldername, filePath, commitId, success, error)
    if type(filePath) ~= 'string' then
        return false
    end

    local commitIdUrl = ''

    if type(commitId) == 'string' and string.lower(commitId) ~= 'master'then
        commitIdUrl = format('?commitId=%s', commitId)
    end

    local url = format('/repos/%s/files/%s/raw%s', self:GetRepoPath(foldername), Mod.WorldShare.Utils.UrlEncode(filePath), commitIdUrl)

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /repos/:repoPath/files/:filePath/history
-- method: GET
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:History()
end

-- url: /repos/:repoPath/files/:filePath
-- method: PUT
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:UpdateFile(foldername, filePath, content, success, error)
    if type(foldername) ~= 'string' or type(filePath) ~= 'string' then
        return false
    end

    local url = format('/repos/%s/files/%s', self:GetRepoPath(foldername), Mod.WorldShare.Utils.UrlEncode(filePath))

    local write = ParaIO.open("/temp/t/" .. filePath, "w")

    write:write(content, #content)
    write:close()

    KeepworkBaseApi:Put(url, { encoding = 'base64', content = Encoding.base64(content) }, nil, success, error)
end

-- url: /repos/:repoPath/files/:filePath
-- method: POST
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
    content binary 必须 文件内容
]]
-- return: object
function KeepworkReposApi:CreateFile(foldername, filePath, content, success, error)
    if type(foldername) ~= 'string' or type(filePath) ~= 'string' then
        return false
    end

    local url = format('/repos/%s/files/%s', self:GetRepoPath(foldername), Mod.WorldShare.Utils.UrlEncode(filePath))

    KeepworkBaseApi:Post(url, { encoding = 'base64', content = Encoding.base64(content) }, nil, success, error)
end

-- url: /repos/:repoPath/files/:filePath
-- method: DELETE
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:RemoveFile(foldername, filePath, success, error)
    if type(foldername) ~= 'string' or type(filePath) ~= 'string' then
        return false
    end

    local url = format('/repos/%s/files/%s', self:GetRepoPath(foldername), Mod.WorldShare.Utils.UrlEncode(filePath))

    KeepworkBaseApi:Delete(url, nil, nil, success, error)
end

-- url: /repos/:repoPath/files/:filePath
-- method: DELETE
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:MoveFile()
end

-- url: /repos/:repoPath/folders/:folderPath
-- method: POST
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:NewFolder()
end

-- url: /repos/:repoPath/folders/:folderPath
-- method: DELETE
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:RemoveFolder()
end

-- url: /repos/:repoPath/folders/:folderPath/rename
-- method: POST 
-- params:
--[[
    repoPath string 必须 仓库路径	
    filePath string 必须 文件路径
]]
-- return: object
function KeepworkReposApi:MoveFolder()
end