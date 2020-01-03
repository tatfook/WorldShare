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
function QiniuRootApi:Upload(token, key, filename, content, success, error)
    local boundary = QiniuRootApi.boundary
    local boundaryLine = "--WebKitFormBoundary" .. boundary .. "\n"

    local postFieldsString = boundaryLine ..
                             "Content-Disposition: form-data; name=\"file\"; filename=\"" .. filename .. "\"\n" ..
                             "Content-Type: application/octet-stream\n" ..
                             "Content-Transfer-Encoding: binary\n\n" ..
                             content .. "\n" ..
                             boundaryLine ..
                             "Content-Disposition: form-data; name=\"x:filename\"\n\n" ..
                             filename ..  "\n" ..
                             boundaryLine ..
                             "Content-Disposition: form-data; name=\"token\"\n\n" ..
                             token ..  "\n" ..
                             boundaryLine ..
                             "Content-Disposition: form-data; name=\"key\"\n\n" ..
                             key .. "\n" .. 
                             boundaryLine

    QiniuBaseApi:PostFields(
        '/',
        {
            ['Host'] = "upload-z2.qiniup.com",
            ['User-Agent'] = "paracraft",
            ["Accept"] = "*/*",
            ["Cache-Control"] = "no-cache",
            ['Content-Type'] = "multipart/form-data; boundary=WebKitFormBoundary" .. boundary,
            ['Content-Length'] = #postFieldsString,
            ['Connection'] = "keep-alive",
        },
        postFieldsString,
        success,
        error
    )
end