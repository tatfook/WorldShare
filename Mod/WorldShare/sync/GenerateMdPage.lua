--[[
Title: GenerateMdPage
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/GenerateMdPage.lua")
local GenerateMdPage = commonlib.gettable("Mod.WorldShare.sync.GenerateMdPage")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local KeepworkGen = commonlib.gettable("Mod.WorldShare.helper.KeepworkGen")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")

local GenerateMdPage = commonlib.gettable("Mod.WorldShare.sync.GenerateMdPage")

function GenerateMdPage:getSetting()
    local dataSourceInfo = GlobalStore.get("dataSourceInfo")
    local userinfo = GlobalStore.get("userinfo")

    return dataSourceInfo, userinfo
end

function GenerateMdPage:genIndexMD(callback)
    local dataSourceInfo, userinfo = GenerateMdPage:getSetting()

    local path = format("%s/paracraft/index.md", userinfo.username)
    local worldList = KeepworkGen:setCommand("WorldList", {userid = userinfo._id})
    local content = KeepworkGen:SetAutoGenContent("", worldList)

    local function update()
        GitService:new():update(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            path,
            content,
            nil,
            function(data, err)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    local function upload()
        GitService:new():upload(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            path,
            content,
            function(data, err)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    GitService:new():getContent(
        dataSourceInfo.keepWorkDataSourceId,
        nil,
        path,
        function(data, size, err)
            if (err == 200) then
                update()
            else
                upload()
            end
        end
    )
end

function GenerateMdPage:genWorldMD(worldInfo, callback)
    local dataSourceInfo, userinfo = GenerateMdPage:getSetting()

    local worldFilePath = format("%s/paracraft/%s.md", userinfo.username, worldInfo.worldsName)

    local KPParacraftMod = {
        link_world_name = worldInfo.name,
        link_world_url = worldInfo.download,
        media_logo = worldInfo.preview,
        link_desc = "",
        link_username = userinfo.username,
        link_update_date = worldInfo.modDate,
        link_version = worldInfo.revision,
        link_opus_id = worldInfo.opusId,
        link_files_totals = worldInfo.filesTotals
    }

    local KPParacraftCMD = KeepworkGen:setCommand("paracraft", KPParacraftMod)

    local worldFile = KeepworkGen:SetAutoGenContent(worldInfo.readme, KPParacraftCMD)
    worldFile = format("%s\r\n%s", worldFile, KeepworkGen:setCommand("comment"))

    local function upload()
        GitService:new():upload(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            worldFilePath,
            worldFile,
            function(data, err)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    local function update()
        GitService:new():update(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            worldFilePath,
            worldFile,
            nil,
            function(isSuccess, path)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    GitService:new():getContent(
        dataSourceInfo.keepWorkDataSourceId,
        nil,
        worldFilePath,
        function(data, size, err)
            if (err == 200) then
                update()
            else
                upload()
            end
        end
    )
end

function GenerateMdPage:deleteWorldMD(_path, callback)
    -- local function deleteFile(keepworkId)
    --     local path = LoginMain.username .. "/paracraft/world_" .. _path .. ".md"
    --     GitService:deleteFileService(
    --         LoginMain.keepWorkDataSource,
    --         path,
    --         "",
    --         function(data, err)
    --             if (type(callback) == "function") then
    --                 callback()
    --             end
    --         end,
    --         keepworkId
    --     )
    -- end
    -- if (LoginMain.dataSourceType == "github") then
    --     deleteFile()
    -- elseif (LoginMain.dataSourceType == "gitlab") then
    --     GitService:getProjectIdByName(
    --         LoginMain.keepWorkDataSource,
    --         function(keepworkId)
    --             deleteFile(keepworkId)
    --         end
    --     )
    -- end
end
