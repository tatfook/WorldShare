--[[
Title: Storage Panoramas API
Author(s):  big
Date:  2020.10.19
Place: Foshan
use the lib:
------------------------------------------------------------
local StoragePanoramasApi = NPL.load("(gl)Mod/WorldShare/api/Storage/Panoramas.lua")
------------------------------------------------------------
]]

local StorageBaseApi = NPL.load('./BaseApi.lua')

local StoragePanoramasApi = NPL.export()

-- url: /panoramas/uploadToken
-- method: POST
-- params:
--[[
    projectId int necessary
    filename string necessary
]]
-- return: object
function StoragePanoramasApi:UploadToken(projectId, filename, success, error)
    local url = "/panoramas/uploadToken"

    if not projectId or type(projectId) ~= 'number' then
        return false
    end

    if not filename or type(filename) ~= 'string' then
        return false
    end
    
    StorageBaseApi:Post(url, { projectId = projectId, filename = filename }, nil, success, error)
end