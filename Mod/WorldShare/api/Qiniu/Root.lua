--[[
Title: Qiniu Root API
Author(s):  big
Date:  2019.12.16
Place: Foshan
use the lib:
------------------------------------------------------------
local QiniuRootApi = NPL.load("(gl)Mod/WorldShare/api/Qiniu/Root.lua")
------------------------------------------------------------
]]

local QiniuBaseApi = NPL.load('./BaseApi.lua')

local QiniuRootApi = NPL.export()

QiniuRootApi.boundary = ParaMisc.md5('')

-- url: /
-- method: POST FIELDS
-- return: object
function QiniuRootApi:Upload(token, key, filename, content, callback)
    QiniuBaseApi:PostFields(
        '/',
        {
            { name = "file", type = "file", filename = filename, value = content },
            { name = "x:filename", type = "string", value = filename },
            { name = "token", type = "string", value = token },
            { name = "key", type = "string", value = key }
        },
        {
            ['Host'] = "upload-z2.qiniup.com",
        },
        callback,
        callback
    )
end