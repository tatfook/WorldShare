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
local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage")

-- service 
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local LocalServiceWorld = NPL.load("../LocalService/LocalServiceWorld.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local KeepworkServiceWorld = NPL.load("../KeepworkService/World.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')

-- helper
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

-- UI
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
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

function Compare:Init(worldPath, callback)
    if type(callback) ~= 'function' then
        return false
    end

    self.worldPath = worldPath
    self.callback = callback

    Mod.WorldShare.Store:Set("world/currentRevision", 0)
    Mod.WorldShare.Store:Set("world/remoteRevision", 0)

    if not self:IsCompareFinish() then
        return false
    end

    self:SetFinish(false)
    self:CompareRevision()
end

function Compare:IsCompareFinish()
    return self.compareFinish == true
end

function Compare:SetFinish(value)
    self.compareFinish = value
end

function Compare:CompareRevision()
    local worldTagPath = self.worldPath .. 'tag.xml'

    if not ParaIO.DoesFileExist(worldTagPath) then
        self:SetFinish(true)
        self.callback(self.JUSTREMOTE, 2)
        return
    end

    local worldTag = LocalService:GetTag(self.worldPath)

    if worldTag and worldTag.kpProjectId == 0 then
        self:SetFinish(true)
        self.callback(self.JUSTLOCAL, 1)
        return
    end

    local localRevision = WorldRevision:new():init(self.worldPath):Checkout()

    local function HandleRevision(data, err)
        if err == 0 or err == 502 then
            self:SetFinish(true)
            self.callback()
            return
        end

        local remoteRevision = tonumber(data) or 0

        Mod.WorldShare.Store:Set("world/currentRevision", localRevision)
        Mod.WorldShare.Store:Set("world/remoteRevision", remoteRevision)

        self:SetFinish(true)

        if localRevision < remoteRevision then
            self.callback(self.REMOTEBIGGER, 5)
            return
        end

        if localRevision > remoteRevision then
            self.callback(self.LOCALBIGGER, 4)
            return
        end

        if localRevision == remoteRevision then
            self.callback(self.EQUAL, 3)
            return
        end
    end

    GitService:GetWorldRevision(worldTag.kpProjectId, true, HandleRevision)
end

function Compare:UpdateSelectWorldInCurrentWorldList(worldName, remoteRevision)
    -- local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')

    -- if not currentWorldList or not worldName then
    --     return false
    -- end

    -- for key, item in ipairs(currentWorldList) do
    --     if item.worldName == worldName then
    --         item.revision = remoteRevision
    --     end
    -- end

    -- Mod.WorldShare.Store:Set('world/compareWorldList', currentWorldList)
end

function Compare:GetCurrentWorldInfo(callback)
    local currentWorld

    Mod.WorldShare.MsgBox:Show(L'正在准备数据，请稍候...')

    local function afterGetInstance()
        Mod.WorldShare.MsgBox:Close()
    
        -- lock share world
        if KeepworkService:IsSignedIn() and
           not GameLogic.IsReadOnly() and
           Mod.WorldShare.Utils:IsSharedWorld(currentWorld) and
           currentWorld.kpProjectId and
           currentWorld.kpProjectId ~= 0 and
           currentWorld.status ~= 1 then
            KeepworkServiceWorld:UpdateLockHeartbeatStart(
                currentWorld.kpProjectId,
                "exclusive",
                currentWorld.revision,
                nil,
                nil
            )
        end

        Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
        Mod.WorldShare.Store:Set("world/currentEnterWorld", currentWorld)

        -- update world tag
        if currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
            WorldCommon.SetWorldTag('kpProjectId', currentWorld.kpProjectId)
        else
            WorldCommon.SetWorldTag('kpProjectId', nil)
        end

        DesktopMenu.LoadMenuItems(true)
        DesktopMenuPage.OnWorldLoaded()
        DesktopMenuPage.Refresh()

        GameLogic.options:ResetWindowTitle() -- update newset worldinfo

        if callback and type(callback) == 'function' then
            callback()
        end
    end

    if Mod.WorldShare.Store:Get("world/readonly") then
        System.World.readonly = true
        GameLogic.options:ResetWindowTitle()
        Mod.WorldShare.Store:Remove("world/readonly")
    end

    if GameLogic.IsReadOnly() then
        local originWorldPath = ParaWorld.GetWorldDirectory()
        local worldTag = WorldCommon.GetWorldInfo() or {}
        local currentRevision = WorldRevision:new():init(originWorldPath):Checkout()
        local localShared = string.match(worldpath or '', 'shared') == 'shared' and true or false

        if worldTag.kpProjectId and worldTag.kpProjectId ~= 0 then
            KeepworkServiceProject:GetProject(worldTag.kpProjectId, function(data, err)
                local shared = false
                if data and data.memberCount and data.memberCount > 1 then
                    shared = true
                end

                KeepworkServiceProject:GetMembers(worldTag.kpProjectId, function(membersData, err)
                    local members = {}

                    for key, item in ipairs(membersData) do
                        members[#members + 1] = item.username
                    end

                    if data and data.project then
                        if data.project.visibility == 0 then
                            data.project.visibility = 0
                        else
                            data.project.visibility = 1
                        end
                    end

                    currentWorld = KeepworkServiceWorld:GenerateWorldInstance({
                        text = worldTag.name,
                        foldername = Mod.WorldShare.Utils.GetFolderName(),
                        name = worldTag.name or '',
                        revision = data.revision,
                        size = 0,
                        modifyTime = '',
                        lastCommitId = data.commitId, 
                        worldpath = originWorldPath,
                        status = 3, -- status should be equal
                        project = data.project,
                        user = {
                            id = data.userId,
                            username = data.username,
                        }, -- { id = xxxx, username = xxxx }
                        kpProjectId = worldTag.kpProjectId,
                        fromProjectId = worldTag.fromProjects,
                        IsFolder = false,
                        is_zip = true,
                        shared = shared,
                        communityWorld = worldTag.communityWorld,
                        isVipWorld = worldTag.isVipWorld,
                        instituteVipEnabled = worldTag.instituteVipEnabled,
                        memberCount = data.memberCount,
                        members = members,
                        remotefile = data.world.archiveUrl,
                    })

                    Mod.WorldShare.Store:Set("world/currentRevision", GameLogic.options:GetRevision())
                    afterGetInstance()
                end)
            end)
        else
            local currentRemoteFile = Mod.WorldShare.Store:Get('world/currentRemoteFile')

            currentWorld = LocalServiceWorld:GenerateWorldInstance({
                IsFolder = false,
                is_zip = true,
                kpProjectId = worldTag.kpProjectId,
                fromProjectId = worldTag.fromProjectId,
                text = worldTag.name,
                size = 0,
                foldername = Mod.WorldShare.Utils.GetFolderName(),
                modifyTime = '',
                worldpath = originWorldPath,
                revision = currentRevision,
                isVipWorld = worldTag.isVipWorld,
                communityWorld = worldTag.communityWorld,
                instituteVipEnabled = worldTag.instituteVipEnabled,
                shared = localShared,
                name = worldTag.name,
                remotefile = currentRemoteFile,
            })

            Mod.WorldShare.Store:Set("world/currentRevision", GameLogic.options:GetRevision())
            afterGetInstance()
        end
    else
        local worldpath = ParaWorld.GetWorldDirectory()

        WorldCommon.LoadWorldTag(worldpath)
        local worldTag = WorldCommon.GetWorldInfo() or {}

        if KeepworkServiceSession:IsSignedIn() and worldTag.kpProjectId and worldTag.kpProjectId ~= 0 then
            local kpProjectId = worldTag.kpProjectId
            local fromProjectId = worldTag.fromProjectId

            KeepworkServiceProject:GetProject(kpProjectId, function(data, err)
                data = data or {}

                local userId = Mod.WorldShare.Store:Get('user/userId')
                local shared = false
                if data and data.memberCount and data.memberCount > 1 then
                    shared = true
                end

                if userId ~= data.userId then
                    local localShared = string.match(worldpath or '', 'shared') == 'shared' and true or false
    
                    if not shared or not localShared then
                        -- covert to new world when different user world
                        currentWorld = LocalServiceWorld:GenerateWorldInstance({
                            IsFolder = true,
                            is_zip = false,
                            text = worldTag.name,
                            foldername = Mod.WorldShare.Utils.GetFolderName(),
                            worldpath = worldpath,
                            kpProjectId = 0,
                            fromProjectId = fromProjectId,
                            name = worldTag.name,
                            revision = WorldRevision:new():init(worldpath):GetDiskRevision(),
                            communityWorld = worldTag.communityWorld,
                            isVipWorld = worldTag.isVipWorld,
                            instituteVipEnabled = worldTag.instituteVipEnabled,
                            shared = false,
                        })
    
                        afterGetInstance()
                        return
                    end
                end

                self:Init(worldpath, function(result)
                    local status

                    if result == self.JUSTLOCAL then
                        status = 1
                    elseif result == self.JUSTREMOTE then
                        status = 2
                    elseif result == self.REMOTEBIGGER then
                        status = 5
                    elseif result == self.LOCALBIGGER then
                        status = 4
                    elseif result == self.EQUAL then
                        status = 3
                    end

                    KeepworkServiceProject:GetMembers(kpProjectId, function(membersData, err)
                        local members = {}
    
                        for key, item in ipairs(membersData) do
                            members[#members + 1] = item.username
                        end

                        if data and data.project then
                            if data.project.visibility == 0 then
                                data.project.visibility = 0
                            else
                                data.project.visibility = 1
                            end
                        end

                        currentWorld = KeepworkServiceWorld:GenerateWorldInstance({
                            IsFolder = true,
                            is_zip = false,
                            text = worldTag.name,
                            foldername = Mod.WorldShare.Utils.GetFolderName(),
                            worldpath = worldpath,
                            kpProjectId = kpProjectId,
                            fromProjectId = fromProjectId,
                            name = worldTag.name,
                            status = status,
                            revision = data.revision,
                            lastCommitId = data.commitId, 
                            project = data.project,
                            user = {
                                id = data.userId,
                                username = data.username,
                            },
                            shared = shared,
                            communityWorld = worldTag.communityWorld,
                            isVipWorld = worldTag.isVipWorld,
                            instituteVipEnabled = worldTag.instituteVipEnabled,
                            memberCount = data.memberCount,
                            members = members,
                            size = 0,
                        })

                        local username = Mod.WorldShare.Store:Get('user/username')
                        local bIsExisted = false

                        for key, item in ipairs(members) do
                            if item == username then
                                bIsExisted = true
                            end
                        end

                        if bIsExisted then
                            System.World.readonly = false
                            GameLogic.options:ResetWindowTitle()
                        else
                            System.World.readonly = true
                            GameLogic.options:ResetWindowTitle()
                        end

                        afterGetInstance()
                    end)
                end)
            end)

            return
        else
            local localShared = string.match(worldpath or '', 'shared') == 'shared' and true or false

            currentWorld = LocalServiceWorld:GenerateWorldInstance({
                IsFolder = true,
                is_zip = false,
                text = worldTag.name,
                foldername = Mod.WorldShare.Utils.GetFolderName(),
                worldpath = worldpath,
                kpProjectId = kpProjectId,
                fromProjectId = fromProjectId,
                name = worldTag.name,
                revision = WorldRevision:new():init(worldpath):GetDiskRevision(),
                communityWorld = worldTag.communityWorld,
                isVipWorld = worldTag.isVipWorld,
                instituteVipEnabled = worldTag.instituteVipEnabled,
                shared = localShared
            })

            if Mod.WorldShare.Utils:IsSharedWorld(currentWorld) then
                System.World.readonly = true
                GameLogic.options:ResetWindowTitle()
            end

            afterGetInstance()
        end
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
                           (not item.status or tonumber(item.status) ~= 2) then
                            filterCurrentWorldList[#filterCurrentWorldList + 1] = item
                        end
                    end

                    currentWorldList = filterCurrentWorldList
                    LocalServiceWorld:SetInternetLocalWorldList(currentWorldList)
                end

                if statusFilter and statusFilter == "ONLINE" then
                    local filterCurrentWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and
                           type(item) == 'table' and
                           item.status and
                           tonumber(item.status) ~= 1
                            then
                            filterCurrentWorldList[#filterCurrentWorldList + 1] = item
                        end
                    end

                    currentWorldList = filterCurrentWorldList
                    LocalServiceWorld:SetInternetLocalWorldList(currentWorldList)
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

function Compare:GetSelectedWorld(index)
    local compareWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')

    if compareWorldList then
        return compareWorldList[index]
    else
        return nil
    end
end

function Compare:GetWorldIndexByFoldername(foldername, share, iszip)
    local currentWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")

    if not currentWorldList or type(currentWorldList) ~= 'table' then
        return false
    end

    for index, item in ipairs(currentWorldList) do
        if foldername == item.foldername and
           share == item.shared and
           iszip == item.is_zip then
            return index
        end
    end
end

function Compare:CheckRevision(worldPath, callback)
    local revisionPath = worldPath .. 'revision.xml'

    if ParaIO.DoesFileExist(revisionPath) then
       return
    end

    local file = ParaIO.open(revisionPath, "w");
    file:WriteString("1")
    file:close();
end