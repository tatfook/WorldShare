--[[
Title: Compare
Author(s): big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
------------------------------------------------------------

status meaning:
1:local only
2:network only
3:both
4:local newest
5:network newest

]]

-- lib
local Encoding = commonlib.gettable("commonlib.Encoding")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local DesktopMenu = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenu")

-- UI
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local LocalServiceWorld = NPL.load("../LocalService/World.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceWorld = NPL.load("../KeepworkService/World.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")

local Compare = NPL.export()

local REMOTEBIGGER = "REMOTEBIGGER"
local JUSTLOCAL = "JUSTLOCAL"
local JUSTREMOTE = "JUSTREMOTE"
local LOCALBIGGER = "LOCALBIGGER"
local EQUAL = "EQUAL"

Compare.REMOTEBIGGER = REMOTEBIGGER
Compare.JUSTLOCAL = JUSTLOCAL
Compare.JUSTREMOTE = JUSTREMOTE
Compare.LOCALBIGGER = LOCALBIGGER
Compare.EQUAL = EQUAL
Compare.compareFinish = true

function Compare:Init(callback)
    if type(callback) ~= 'function' then
        return false
    end

    self.callback = callback

    Mod.WorldShare.Store:Set("world/currentRevision", 0)
    Mod.WorldShare.Store:Set("world/remoteRevision", 0)

    if not self:IsCompareFinish() then
        return false
    end

    self:SetFinish(false)
    self:GetCompareResult()
end

function Compare:IsCompareFinish()
    return self.compareFinish == true
end

function Compare:SetFinish(value)
    self.compareFinish = value
end

function Compare:GetCompareResult()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or currentWorld.is_zip then
        self:SetFinish(true)
        self.callback(false)

        return false
    end

    if currentWorld.status == 1 then
        CreateWorld:CheckRevision()
        local currentRevision = WorldRevision:new():init(currentWorld.worldpath):Checkout()
        Mod.WorldShare.Store:Set("world/currentRevision", currentRevision)

        self:SetFinish(true)
        self.callback(JUSTLOCAL)
        return true
    end

    if currentWorld.status == 2 then
        self:SetFinish(true)
        self.callback(JUSTREMOTE)
        return true
    end

    self:CompareRevision()
end

-- create revision try times
Compare.createRevisionTimes = 0

function Compare:CompareRevision()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or not currentWorld.worldpath then
        self:SetFinish(true)
        self.callback(false)
        return false
    end

    local currentRevision = WorldRevision:new():init(currentWorld.worldpath):Checkout()
    local remoteRevision = 0

    if self:HasRevision() then
        self.createRevisionTimes = 0

        local function CompareRevision(currentRevision, remoteRevision)
            if remoteRevision == 0 then
                currentWorld.status = 1
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return JUSTLOCAL
            end

            if currentRevision < remoteRevision then
                currentWorld.status = 4
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return REMOTEBIGGER
            end

            if currentRevision > remoteRevision then
                currentWorld.status = 5
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return LOCALBIGGER
            end

            if currentRevision == remoteRevision then
                currentWorld.status = 3
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return EQUAL
            end
        end

        if currentWorld and not currentWorld.kpProjectId then
            self:SetFinish(true)
            self.callback(false)
            return true
        end

        local function HandleRevision(data, err)
            if err == 0 or err == 502 then
                self:SetFinish(true)
                self.callback(false)
                return false
            end

            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            self:UpdateSelectWorldInCurrentWorldList(currentWorld.foldername, remoteRevision)

            Mod.WorldShare.Store:Set("world/currentRevision", currentRevision)
            Mod.WorldShare.Store:Set("world/remoteRevision", remoteRevision)

            local result = CompareRevision(currentRevision, remoteRevision)

            self:SetFinish(true)
            self.callback(result)
        end

        GitService:GetWorldRevision(currentWorld.kpProjectId, true, HandleRevision)
    else
        self.createRevisionTimes = self.createRevisionTimes + 1

        if self.createRevisionTimes > 3 then
            self.createRevisionTimes = 0
            self:SetFinish(true)
            return false
        end

        CreateWorld:CheckRevision()
        self:CompareRevision(callback)
    end
end

function Compare:UpdateSelectWorldInCurrentWorldList(worldName, remoteRevision)
    local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')

    if not currentWorldList or not worldName then
        return false
    end

    for key, item in ipairs(currentWorldList) do
        if item.worldName == worldName then
            item.revision = remoteRevision
        end
    end

    Mod.WorldShare.Store:Set('world/compareWorldList', currentWorldList)
end

function Compare:HasRevision()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    local localFiles = LocalService:LoadFiles(currentWorld and currentWorld.worldpath)
    local hasRevision = false

    for key, file in ipairs(localFiles) do
        if string.lower(file.filename) == "revision.xml" then
            hasRevision = true
            break
        end
    end

    return hasRevision
end

function Compare:GetCurrentWorldInfo(callback)
    local currentWorld

    if Mod.WorldShare.Store:Get("world/readonly") then
        System.World.readonly = true
        GameLogic.options:ResetWindowTitle()
        Mod.WorldShare.Store:Remove("world/readonly")
    end

    if GameLogic.IsReadOnly() then
        local originWorldPath = ParaWorld.GetWorldDirectory()
        local worldTag = WorldCommon.GetWorldInfo() or {}

        currentWorld = {
            IsFolder = false,
            is_zip = true,
            Title = worldTag.name,
            text = worldTag.name,
            author = "None",
            costTime = "0:0:0",
            filesize = 0,
            foldername = Mod.WorldShare.Utils.GetFolderName(),
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
            worldpath = originWorldPath,
            kpProjectId = worldTag.kpProjectId,
            fromProjectId = tonumber(worldTag.fromProjects)
        }

        local currentRemoteWorld = Mod.WorldShare.Store:Get('world/currentRemoteWorld')
        currentWorld.remoteWorld = commonlib.copy(currentRemoteWorld)

        Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
        Mod.WorldShare.Store:Set("world/currentRevision", GameLogic.options:GetRevision())
    else
        local currentWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")
    
        if currentWorldList then
            local searchCurrentWorld = nil
            local worldpath = ParaWorld.GetWorldDirectory()
            local shared = string.match(worldpath, "shared") == "shared" and true or nil

            local realFoldername = Mod.WorldShare.Utils:GetFolderName() or ''
            for key, item in ipairs(currentWorldList) do
                if item.real_foldername == realFoldername and
                   item.shared == shared and 
                   not item.is_zip then
                    searchCurrentWorld = item
                    break
                end
            end

            if searchCurrentWorld then
                currentWorld = searchCurrentWorld

                if currentWorld.status == 2 then
                    currentWorld.status = 3
                    currentWorld.worldpath = worldpath
                    currentWorld.local_tagname = currentWorld.remote_tagname
                end

                local worldTag = LocalService:GetTag(currentWorld.worldpath)

                if type(worldTag) == 'table' then
                    currentWorld.kpProjectId = tonumber(worldTag.kpProjectId)
                    currentWorld.fromProjectId = tonumber(worldTag.fromProjects)

                    if worldTag and worldTag.seed ~= '' then
                        currentWorld.foldername = worldTag.seed
                    else
                        currentWorld.foldername = currentWorld.real_foldername
                    end
                end

                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
            end
        end
    end

    if not currentWorld then
        local worldpath = ParaWorld.GetWorldDirectory()

        WorldCommon.LoadWorldTag(worldpath)
        local worldTag = WorldCommon.GetWorldInfo() or {}

        currentWorld = {
            IsFolder = true,
            is_zip = false,
            Title = worldTag.name,
            text = worldTag.name,
            author = "None",
            costTime = "0:0:0",
            filesize = 0,
            real_foldername = Mod.WorldShare.Utils.GetFolderName(),
            foldername = (worldTag.seed and worldTag.seed ~= '') and worldTag.seed or Mod.WorldShare.Utils.GetFolderName(),
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
        }

        if worldTag.kpProjectId then
            currentWorld.kpProjectId = worldTag.kpProjectId
        else
            currentWorld.status = 1
        end

        if type(worldTag) == 'table' then
            currentWorld.kpProjectId = tonumber(worldTag.kpProjectId)
            currentWorld.fromProjectId = tonumber(worldTag.fromProjects)
        end

        echo('from world load!!!', true)
        echo(currentWorld, true)

        Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
    end

    -- for offline world
    if not KeepworkService:IsSignedIn() and currentWorld.shared then
        System.World.readonly = true
        GameLogic.options:ResetWindowTitle()
    end

    if not GameLogic.IsReadOnly() and (currentWorld.project and currentWorld.project.memberCount or 0) > 1 then
        KeepworkServiceWorld:UpdateLockHeartbeatStart(currentWorld.kpProjectId, "exclusive", currentWorld.revision, nil, nil)
    end

    Mod.WorldShare.Store:Set("world/currentEnterWorld", currentWorld)

    DesktopMenu.LoadMenuItems(true)

    if type(callback) == 'function' then
        callback()
    end
end

function Compare:RefreshWorldList(callback, statusFilter)
    local localWorlds = LocalServiceWorld:GetWorldList()

    if not KeepworkService:IsSignedIn() then
        local currentWorldList = LocalServiceWorld:MergeInternetLocalWorldList(localWorlds)

        local searchText = Mod.WorldShare.Store:Get("world/searchText")

        if type(searchText) == "string" and searchText ~= "" then
            local searchWorldList = {}

            for key, item in ipairs(currentWorldList) do
                if item and item.text and string.match(string.lower(item.text), string.lower(searchText))then
                    searchWorldList[#searchWorldList + 1] = item
                elseif item and item.kpProjectId and string.match(string.lower(item.kpProjectId), string.lower(searchText)) then
                    searchWorldList[#searchWorldList + 1] = item
                end
            end

            currentWorldList = searchWorldList
            LocalServiceWorld:SetInternetLocalWorldList(currentWorldList)
        end

        self.SortWorldList(currentWorldList)
        Mod.WorldShare.Store:Set("world/compareWorldList", currentWorldList)

        if type(callback) == 'function' then
            callback(currentWorldList)
        end
    else
        KeepworkServiceWorld:MergeRemoteWorldList(
            localWorlds,
            function(currentWorldList)
                currentWorldList = LocalServiceWorld:MergeInternetLocalWorldList(currentWorldList)

                if statusFilter and statusFilter == 'LOCAL' then
                    local filterCurrentWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and
                           type(item) == 'table' and
                           (type(item.status) == 'number' or type(item.status) == 'string') and
                           tonumber(item.status) ~= 2 then
                            filterCurrentWorldList[#filterCurrentWorldList + 1] = item
                        end
                    end

                    currentWorldList = filterCurrentWorldList
                end

                if statusFilter and statusFilter == "ONLINE" then
                    local filterCurrentWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and
                           type(item) == 'table' and
                           (type(item.status) == 'number' or type(item.status) == 'string') and
                           tonumber(item.status) ~= 1 then
                            filterCurrentWorldList[#filterCurrentWorldList + 1] = item
                        end
                    end

                    currentWorldList = filterCurrentWorldList
                end

                local searchText = Mod.WorldShare.Store:Get("world/searchText")

                if type(searchText) == "string" and searchText ~= "" then
                    local searchWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and item.text and string.match(string.lower(item.text), string.lower(searchText))then
                            searchWorldList[#searchWorldList + 1] = item
                        elseif item and item.kpProjectId and string.match(string.lower(item.kpProjectId), string.lower(searchText)) then
                            searchWorldList[#searchWorldList + 1] = item
                        end
                    end

                    currentWorldList = searchWorldList
                    LocalServiceWorld:SetInternetLocalWorldList(currentWorldList)
                end

                self.SortWorldList(currentWorldList)

                Mod.WorldShare.Store:Set("world/compareWorldList", currentWorldList)
                if type(callback) == 'function' then
                    callback(currentWorldList)
                end
            end
        )
    end
end

function Compare.SortWorldList(currentWorldList)
    if type(currentWorldList) == 'table' and #currentWorldList > 0 then
        local tmp = 0

        for i = 1, #currentWorldList - 1 do
            for j = 1, #currentWorldList - i do
                local curItemModifyTime = 0
                local nextItemModifyTime = 0

                if currentWorldList[j] and currentWorldList[j].modifyTime then
                    curItemModifyTime = currentWorldList[j].modifyTime
                end

                if currentWorldList[j + 1] and currentWorldList[j + 1].modifyTime then
                    nextItemModifyTime = currentWorldList[j + 1].modifyTime
                end

                if curItemModifyTime < nextItemModifyTime then
                    tmp = currentWorldList[j]
                    currentWorldList[j] = currentWorldList[j + 1]
                    currentWorldList[j + 1] = tmp
                end
            end
        end
    end
end
