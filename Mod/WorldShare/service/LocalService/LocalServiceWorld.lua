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
    local sharedWorldList = self:GetSharedWorldList()

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

    for key, item in ipairs(sharedWorldList) do
        localWorlds[#localWorlds + 1] = item
    end

    for key, value in ipairs(localWorlds) do
        if value.IsFolder then
            value.worldpath = value.worldpath .. '/'

            local worldRevision = WorldRevision:new():init(value.worldpath)
            value.revision = worldRevision:GetDiskRevision()

            local tag = SaveWorldHandler:new():Init(value.worldpath):LoadWorldInfo()

            if type(tag) ~= 'table' then
                return false
            end

            if tag.kpProjectId then
                value.kpProjectId = tag.kpProjectId
                value.hasPid = true
            else
                value.hasPid = false
            end

            if tag.size then
                value.size = tag.size
            else
                value.size = 0
            end

            value.local_tagname = tag.name
            value.is_zip = false
            value.vipEnabled = tag.vipEnabled
            value.institueEnabled = tag.instituteEnabled
        else
            value.foldername = value.Title
            value.text = value.Title
            value.is_zip = true
            value.remotefile = format("local://%s", value.worldpath)
        end

        value.modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(value.writedate)
    end

    return localWorlds
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
                                        Title = display_name,
                                        writedate = item.writedate, filesize=item.filesize,
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
                                        IsFolder=true, time_text=item.time_text,
                                        text = worldUsername .. "/" .. display_name,
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
    local internetLocalWorldList = self:GetInternetLocalWorldList()

    for CKey, CItem in ipairs(currentWorldList) do
        for IKey, IItem in ipairs(internetLocalWorldList) do
            if not CItem.shared and IItem.foldername == CItem.foldername then
                if IItem.is_zip == CItem.is_zip then 
                    for key, value in pairs(IItem) do
                        if(key ~= "revision") then
                            CItem[key] = value
                        end
                    end
                    break
                end
            end
        end
    end

    InternetLoadWorld.cur_ds = currentWorldList
    
    return currentWorldList
end

function LocalServiceWorld:SetWorldInstanceByFoldername(foldername)
    if not foldername or type(foldername) ~= 'string' then
        return false
    end

    local worldpath = Mod.WorldShare.Utils.GetWorldFolderFullPath() .. '/'  .. foldername .. '/'

    local currentWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")
    local currentWorld = nil

    if currentWorldList then
        local searchCurrentWorld = nil
        local shared = string.match(worldpath, "shared") == "shared" and true or nil

        for key, item in ipairs(currentWorldList) do
            if item.foldername == foldername and
                item.shared == shared and 
                not item.is_zip then
                searchCurrentWorld = item
                break
            end
        end

        if searchCurrentWorld then
            currentWorld = searchCurrentWorld
        end
    end

    if not currentWorld then
        local worldTag = LocalService:GetTag(worldpath) or {}

        currentWorld = {
            IsFolder = true,
            is_zip = false,
            Title = worldTag.name or '',
            text = worldTag.name or '',
            author = "None",
            costTime = "0:0:0",
            filesize = 0,
            foldername = foldername,
            grade = "primary",
            icon = "Texture/3DMapSystem/common/page_world.png",
            ip = "127.0.0.1",
            mode = "survival",
            modifyTime = 0,
            nid = "",
            order = 0,
            preview = "",
            progress = "0",
            size = 0,
            worldpath = worldpath,
            remotefile = format("local://%s", worldpath)
        }

        if type(worldTag) == 'table' then
            currentWorld.kpProjectId = tonumber(worldTag.kpProjectId)
            currentWorld.fromProjectId = tonumber(worldTag.fromProjects)
        end
    end

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
