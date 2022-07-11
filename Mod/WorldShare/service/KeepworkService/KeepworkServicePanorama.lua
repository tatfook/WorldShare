--[[
Title: KeepworkService Panorama
Author(s):  big
Date:  2020.10.19
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServicePanorama = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServicePanorama.lua')
------------------------------------------------------------
]]

local KeepworkServicePanorama = NPL.export()

-- api
local StoragePanoramasApi = NPL.load('(gl)Mod/WorldShare/api/Storage/Panoramas.lua')
local QiniuRootApi = NPL.load('(gl)Mod/WorldShare/api/Qiniu/Root.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectsApi.lua')

-- service
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')

KeepworkServicePanorama.uploadIndex = 0
KeepworkServicePanorama.fileArray = {}

function KeepworkServicePanorama:GetBasePath()
    return Mod.WorldShare.Utils.GetRootFolderFullPath() .. 'Screen Shots/'
end

function KeepworkServicePanorama:Upload(callback, recursive)
    if not callback or type(callback) ~= 'function' then
        return false
    end

    if self.uploadIndex ~= 0 and not recursive then
        return false
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentEnterWorld or not currentEnterWorld.kpProjectId or currentEnterWorld.kpProjectId == 0 then
        return false
    end

    local filename = self.uploadIndex .. '.jpg'
    local projectId = currentEnterWorld.kpProjectId

    if self.uploadIndex > 5 then
        -- return
        callback(true, self.fileArray)
        self.uploadIndex = 0
        self.fileArray = {}
        return
    end

    StoragePanoramasApi:UploadToken(
        projectId,
        tostring(self.uploadIndex),
        function(data, err)
            if err ~= 200 or not data or not data.data then
                callback(false)
                return
            end

            local content = LocalService:GetFileContent(self:GetBasePath() .. filename)

            QiniuRootApi:Upload(data.data.token, data.data.key, data.data.key, content, function(data, err)
                if err ~= 200 or not data or not data.data or not data.data.url then
                    callback(false)
                    return
                end

                self.uploadIndex = self.uploadIndex + 1
                self.fileArray[#self.fileArray + 1] = data.data.url
                self:Upload(callback, true)
            end)
        end,
        function()
            callback(false)
        end
    )
end

function KeepworkServicePanorama:GenerateMiniProgramCode(callback)
    if not callback or type(callback) ~= 'function' then
        return false
    end
    
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentEnterWorld or not currentEnterWorld.kpProjectId or currentEnterWorld.kpProjectId == 0 then
        return false
    end

    KeepworkProjectsApi:ShareWxacode(
        tonumber(currentEnterWorld.kpProjectId),
        function(data, err)
            if err ~= 200 or not data or not data.wxacode then
                callback(false)
                return
            end

            callback(true, data.wxacode)
        end,
        function(data, err)
            callback(false)
        end
    )
end