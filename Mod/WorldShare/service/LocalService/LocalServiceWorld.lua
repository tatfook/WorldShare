--[[
Title: LocalService World
Author(s):  big
Date:  2020.2.12
Place: Foshan
use the lib:
------------------------------------------------------------
local LocalServiceWorld = NPL.load("(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua")
------------------------------------------------------------
]]

-- service
local LocalService = NPL.load('../LocalService.lua')
local KeepworkService = NPL.load('../KeepworkService.lua')
local KeepworkServiceSession = NPL.load('../KeepworkService/Session.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')

-- libs
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter")

local LocalServiceWorld = NPL.export()

function LocalServiceWorld:GetWorldList()
    local localWorlds = LocalLoadWorld.BuildLocalWorldList(true)
    local filterLocalWorlds = {}

    -- not main world filter
    for key, item in ipairs(localWorlds) do
        if KeepworkServiceSession:IsSignedIn() then
            local username = Mod.WorldShare.Store:Get('user/username')

            if item and item.foldername then
                local matchFoldername = string.match(item.foldername, "(.+)_main$")

                if matchFoldername then
                    if matchFoldername == username then
                        filterLocalWorlds[#filterLocalWorlds + 1] = item
                    end
                else
                    filterLocalWorlds[#filterLocalWorlds + 1] = item
                end
            end
        else
            if item and item.foldername and not string.match(item.foldername, "_main$") then
                filterLocalWorlds[#filterLocalWorlds + 1] = item
            end
        end
    end

    localWorlds = filterLocalWorlds

    local sharedWorldList = self:GetSharedWorldList()

    for key, item in ipairs(sharedWorldList) do
        localWorlds[#localWorlds + 1] = item
    end

    local worldList = {}

    for key, value in ipairs(localWorlds) do
        local foldername = ''
        local Title = ''
        local text = ''
        local is_zip
        local revision = 0
        local kpProjectId = 0
        local size = 0
        local name = ''
        local isVipWorld = false
        local instituteVipEnabled = false
        local modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(value.writedate)

        if value.IsFolder then
            value.worldpath = value.worldpath .. '/'
            is_zip = false
            revision = WorldRevision:new():init(value.worldpath):GetDiskRevision()
            foldername = value.foldername
            Title = value.Title
            text = value.Title

            local tag = SaveWorldHandler:new():Init(value.worldpath):LoadWorldInfo()
            kpProjectId = tag.kpProjectId
            size = tag.size
            name = tag.name
            isVipWorld = tag.isVipWorld
            instituteVipEnabled = tag.instituteVipEnabled
        else
            foldername = value.Title
            Title = value.Title
            text = value.Title
            
            is_zip = true
        end

        worldList[#worldList + 1] = self:GenerateWorldInstance({
            IsFolder = value.IsFolder,
            is_zip = is_zip,
            kpProjectId = kpProjectId,
            text = text,
            size = size,
            foldername = foldername,
            modifyTime = modifyTime,
            worldpath = value.worldpath,
            name = name,
            revision = revision,
            isVipWorld = isVipWorld,
            instituteVipEnabled = instituteVipEnabled,
            shared = value.shared or false
        })
    end

    return worldList
end

function LocalServiceWorld:GetSharedWorldList()
    local dsWorlds = {}
    local SelectedWorld_Index = nil
    local username = Mod.WorldShare.Store:Get("user/username")

    local function AddWorldToDS(worldInfo)
        if LocalLoadWorld.AutoCompleteWorldInfo(worldInfo) then
            table.insert(dsWorlds, worldInfo)
        end
    end

    local sharedWorldPath = LocalLoadWorld.GetDefaultSaveWorldPath() .. '/_shared/'
    local sharedFiles = LocalService:Find(sharedWorldPath)

    for key, item in ipairs(sharedFiles) do
        if item and item.filesize == 0 and item.filename ~= username then
            local folderPath = sharedWorldPath .. item.filename 

            local output = LocalLoadWorld.SearchFiles(nil, folderPath, LocalLoadWorld.MaxItemPerFolder)

            if output and #output > 0 then
                for _, item in ipairs(output) do
                    local bLoadedWorld
                    local xmlRoot = ParaXML.LuaXML_ParseFile(folderPath .. "/" .. item.filename .. "/tag.xml")
        
                    if xmlRoot then
                        for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
                            if node.attr then
                                local display_name = node.attr.name or item.filename
                                local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
        
                                if filenameUTF8 ~= node.attr.name then
                                    -- show dir name if differs from world name
                                    display_name = format("%s(%s)", node.attr.name or "", filenameUTF8)
                                end

                                local worldpath = folderPath .. "/" .. item.filename
                                local remotefile = "local://" .. worldpath
                                local worldUsername = Mod.WorldShare:GetWorldData("username", worldpath .. "/") or ""

                                -- only add world with the same nid
                                AddWorldToDS(
                                    {
                                        worldpath = worldpath,
                                        remotefile = remotefile,
                                        foldername = filenameUTF8,
                                        Title = worldUsername .. "/" .. display_name,
                                        writedate = item.writedate,
                                        filesize = item.filesize,
                                        nid = node.attr.nid,
                                        -- world's new property
                                        author = item.author or "None",
                                        mode = item.mode or "survival",
                                        -- the max value of the progress is 1
                                        progress = item.progress or "0",
                                        -- the format of costTime:  "day:hour:minute"
                                        costTime = item.progress or "0:0:0",
                                        -- maybe grade is "primary" or "middle" or "adventure" or "difficulty" or "ultimate"
                                        grade = item.grade or "primary",
                                        ip = item.ip or "127.0.0.1",
                                        order = item.order,
                                        IsFolder = true,
                                        time_text = item.time_text,
                                        shared = true,
                                    }
                                )
        
                                bLoadedWorld = true
                                break
                            end
                        end
                    end

                    if not bLoadedWorld and ParaIO.DoesFileExist(folderPath .. "/" .. item.filename .. "/worldconfig.txt") then
                        local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
        
                        LOG.std(nil, "info", "LocalWorld", "missing tag.xml in %s", filenameUTF8)
                        AddWorldToDS(
                            {
                                worldpath = folderPath.."/"..item.filename, 
                                foldername = filenameUTF8,
                                Title = filenameUTF8,
                                writedate = item.writedate, filesize=item.filesize,
                                order = item.order,
                                IsFolder=true
                            }
                        )	
                        bLoadedWorld = true
                    end	
                end
            end
        end
    end

    table.sort(dsWorlds, function(a, b)
        return (a.order or 0) > (b.order or 0)
    end)

    return dsWorlds
end

function LocalServiceWorld:GetInternetLocalWorldList()
  local ServerPage = InternetLoadWorld.GetCurrentServerPage()

  RemoteServerList:new():Init(
      "local",
      "localworld",
      function(bSucceed, serverlist)
          if not serverlist:IsValid() then
              return false
          end

          ServerPage.ds = serverlist.worlds or {}
          InternetLoadWorld.OnChangeServerPage()
      end
  )

  return ServerPage.ds or {}
end

function LocalServiceWorld:SetInternetLocalWorldList(currentWorldList)
    InternetLoadWorld.cur_ds = currentWorldList
end

function LocalServiceWorld:MergeInternetLocalWorldList(currentWorldList)
    InternetLoadWorld.cur_ds = currentWorldList
    
    return currentWorldList
end

function LocalServiceWorld:SetWorldInstanceByFoldername(foldername)
    if not foldername or type(foldername) ~= 'string' then
        return false
    end

    local worldpath = Mod.WorldShare.Utils.GetWorldFolderFullPath() .. '/' ..
                      commonlib.Encoding.Utf8ToDefault(foldername) .. '/'

    local currentWorld = nil

    local worldTag = LocalService:GetTag(worldpath) or {}
    local revision = WorldRevision:new():init(worldpath):GetDiskRevision()
    local shared = string.match(worldpath, "shared") == "shared" and true or false
    
    if name ~= commonlib.Encoding.DefaultToUtf8(foldername) then
        text = name .. '(' .. commonlib.Encoding.DefaultToUtf8(foldername) .. ')'
    end

    currentWorld = self:GenerateWorldInstance({
        IsFolder = true,
        is_zip = false,
        text = worldTag.name,
        foldername = foldername,
        worldpath = worldpath,
        kpProjectId = worldTag.kpProjectId,
        fromProjectId = worldTag.fromProjects,
        name = worldTag.name,
        modifyTime = 0,
        revision = revision,
        isVipWorld = worldTag.isVipWorld,
        communityWorld = worldTag.communityWorld,
        instituteVipEnabled = worldTag.instituteVipEnabled,
        shared = shared
    })

    Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

    return currentWorld
end

function LocalServiceWorld:GetMainWorldProjectId()
    if not ParaWorldLoginAdapter or not ParaWorldLoginAdapter.ids then
        return false
    end

    local ids = ParaWorldLoginAdapter.ids[KeepworkService:GetEnv()]

    if ids and ids[1] then
        return ids[1]
    else
        return false
    end
end

function LocalServiceWorld:SetCommunityWorld(bValue)
    WorldCommon.SetWorldTag('communityWorld', bValue)
end

function LocalServiceWorld:IsCommunityWorld()
    return WorldCommon.GetWorldTag('communityWorld')
end

-- exec from save_world_info filter
function LocalServiceWorld:SaveWorldInfo(ctx, node)
    if (type(ctx) ~= 'table' or
        type(node) ~= 'table' or
        type(node.attr) ~= 'table') then
        return false
    end

    node.attr.clientversion = LocalService:GetClientVersion() or ctx.clientversion
    node.attr.communityWorld = ctx.communityWorld or false
    node.attr.instituteVipEnabled = ctx.instituteVipEnabled or false
    node.attr.kpProjectId = ctx.kpProjectId and tonumber(ctx.kpProjectId) or 0
end

function LocalServiceWorld:LoadWorldInfo(ctx, node)
    if type(ctx) ~= 'table' or
       type(node) ~= 'table' or
       type(node.attr) ~= 'table' then
        return false
    end

    ctx.communityWorld = ctx.communityWorld == 'true' or ctx.communityWorld == true
    ctx.instituteVipEnabled = ctx.instituteVipEnabled == 'true' or ctx.instituteVipEnabled == true
    ctx.kpProjectId = tonumber(ctx.kpProjectId) or 0
end

function LocalServiceWorld:CheckWorldIsCorrect(world)
    if not world or type(world) ~= 'table' or not world.worldpath then
        return
    end

    local output = commonlib.Files.Find({}, world.worldpath, 0, 500, "worldconfig.txt")

    if not output or #output == 0 then
        return false
    else
        return true
    end
end

function LocalServiceWorld:GenerateWorldInstance(params)
    if not params or type(params) ~= 'table' then
        return {}
    end

    local remotefile = ''

    if params.remotefile then
        remotefile = params.remotefile
    else
        remotefile = format('local://%s', (params.worldpath or ''))
    end

    return {
        IsFolder = params.IsFolder == 'true' or params.IsFolder == true,
        is_zip = params.is_zip == 'true' or params.is_zip == true,
        kpProjectId = params.kpProjectId and tonumber(params.kpProjectId) or 0,
        fromProjectId = params.fromProjectId and tonumber(params.fromProjectId) or 0,
        hasPid = params.kpProjectId and params.kpProjectId ~= 0 and true or false,
        text = params.text or '',
        size = params.size or 0,
        foldername = params.foldername or '',
        modifyTime = params.modifyTime or '',
        worldpath = params.worldpath or '',
        remotefile = remotefile,
        revision = params.revision or 0,
        isVipWorld = params.isVipWorld or false,
        communityWorld = params.communityWorld or false,
        instituteVipEnabled = params.instituteVipEnabled or false,
        shared = params.shared or false,
        name = params.name or '',
    }
end

function LocalServiceWorld:DownLoadZipWorld(foldername, username, lastCommitId, worldpath, callback)
    GitService:DownloadZIP(
        foldername,
        username or nil,
        lastCommitId,
        function(bSuccess, downloadPath)
            if not bSuccess then
                return
            end

            LocalService:MoveZipToFolder('temp/world_temp_download/', downloadPath, function()
                local fileList = LocalService:LoadFiles('temp/world_temp_download/', true, true)
    
                if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
                    return
                end
    
                local zipRootPath = ''
    
                if fileList[1] and fileList[1].filesize == 0 then
                    zipRootPath = fileList[1].filename
                end
    
                ParaIO.CreateDirectory(worldpath)
    
                for key, item in ipairs(fileList) do
                    if key ~= 1 then
                        local relativePath = commonlib.Encoding.Utf8ToDefault(item.filename:gsub(zipRootPath .. '/', ''))
    
                        if item.filesize == 0 then
                            local folderPath = worldpath .. relativePath .. '/'
    
                            ParaIO.CreateDirectory(folderPath)
                        else
                            local filePath = worldpath .. relativePath
    
                            ParaIO.MoveFile(item.file_path, filePath)
                        end
                    end
                end
    
                ParaIO.DeleteFile('temp/world_temp_download/')
    
                if callback and type(callback) then
                    callback()
                end
            end)
        end
    )
end