--[[
Title: Keepwork Repos API
Author(s): big
CreateDate: 2019.11.8
ModifyDate: 2022.7.11
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkReposApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkReposApi.lua')
------------------------------------------------------------
]]

-- libs
local FileDownloader = commonlib.gettable('Mod.WorldShare.service.FileDownloader.FileDownloader')
local Encoding = commonlib.gettable('System.Encoding')

-- api
local KeepworkBaseApi = NPL.load('./BaseApi.lua')

-- helper
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

local KeepworkReposApi = NPL.export()

function KeepworkReposApi:GetRepoPath(foldername, username)
    username = username or Mod.WorldShare.Store:Get('user/username')

    if type(username) ~= 'string' or type(foldername) ~= 'string' then
        return ''
    else
        return Mod.WorldShare.Utils.UrlEncode(username .. '/' .. GitEncoding.Base32(foldername))
    end
end

-- url: /repos/:repoPath/download?ref=:ref
-- method: GET
-- params:
--[[
    repoPath string 必须 仓库路径	
    ref string 必须 ref
]]
-- return: object
function KeepworkReposApi:Download(foldername, username, commitId, success, error)
    local url = format('%s/repos/%s/download?ref=%s', KeepworkBaseApi:GetApi(), self:GetRepoPath(foldername, username), commitId)

    FileDownloader:new():Init(
        foldername,
        url,
        'temp/archive.zip',
        function(bSuccess, downloadPath)
            if bSuccess then
                if success and type(success) == 'function' then
                    success(true, downloadPath)
                end
            else
                if error and type(error) == 'function' then
                    error(false)
                end
            end

        end,
        'access plus 5 mins',
        false
    )
end

-- url: /repos/:repoPath/tree
-- method: GET
-- params:
--[[
    repoPath string necessary repo path
    ref string necessary commitId
    recursive string not necessary Is get recursive files
]]
-- return: object
function KeepworkReposApi:Tree(foldername, username, commitId, success, error)
    local url = ''

    if type(foldername) ~= 'string' or type(commitId) ~= 'string' or commitId == 'master' then
        url = format('/repos/%s/tree?recursive=true', self:GetRepoPath(foldername, username))
    else
        url = format('/repos/%s/tree?recursive=true&commitId=%s', self:GetRepoPath(foldername, username), commitId)
    end

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- url: /repos/:repoPath/commitInfo
-- method: GET
-- params: [[]]
-- return: object
function KeepworkReposApi:CommitInfo(foldername, username, success, error)
    if type(foldername) ~= 'string' then
        return false
    end

    local url = format('/repos/%s/commitInfo', self:GetRepoPath(foldername, username))

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
function KeepworkReposApi:Raw(foldername, username, filePath, commitId, success, error, cdnState, noTryStatus)
    if not filePath or type(filePath) ~= 'string' then
        return
    end

    local commitIdUrl = ''

    if commitId and
       type(commitId) == 'string' and
       string.lower(commitId) ~= 'master'then
        commitIdUrl = format('?commitId=%s', commitId)
    end

    local url =
        format(
            '/repos/%s/files/%s/raw%s',
            self:GetRepoPath(foldername, username),
            Mod.WorldShare.Utils.EncodeURIComponent(filePath),
            commitIdUrl
        )

    KeepworkBaseApi:Get(url, nil, nil, success, error, noTryStatus, nil, cdnState)
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
function KeepworkReposApi:UpdateFile(foldername, username, filePath, content, success, error)
    if not foldername or
       type(foldername) ~= 'string' or
       not filePath or
       type(filePath) ~= 'string' then
        return
    end

    local url = format('/repos/%s/files/%s', self:GetRepoPath(foldername, username), Mod.WorldShare.Utils.EncodeURIComponent(filePath))

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
function KeepworkReposApi:CreateFile(foldername, username, filePath, content, success, error)
    if not foldername or
       type(foldername) ~= 'string' or
       not filePath or
       type(filePath) ~= 'string' then
        return
    end

    local url = format('/repos/%s/files/%s', self:GetRepoPath(foldername, username), Mod.WorldShare.Utils.EncodeURIComponent(filePath))

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
function KeepworkReposApi:RemoveFile(foldername, username, filePath, success, error)
    if not foldername or
       type(foldername) ~= 'string' or
       not filePath or
       type(filePath) ~= 'string' then
        return
    end

    local url = format('/repos/%s/files/%s', self:GetRepoPath(foldername, username), Mod.WorldShare.Utils.EncodeURIComponent(filePath))

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