--[[
Title: KeepworkService World
Author(s):  big
Date:  2019.12.9
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
------------------------------------------------------------
]]

-- lib
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")

-- service
local KeepworkService = NPL.load('../KeepworkService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")

-- api
local KeepworkWorldsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Worlds.lua")
local KeepworkProjectsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Projects.lua")
local KeepworkWorldLocksApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/WorldLocks.lua")

local KeepworkServiceWorld = NPL.export()

KeepworkServiceWorld.lockHeartbeat = false

function KeepworkServiceWorld:GetSingleFile(pid, filename, callback, cdnState)
    self:GetSingleFileByCommitId(pid, nil, filename, callback, cdnState)
end

function KeepworkServiceWorld:GetSingleFileByCommitId(pid, commitId, filename, callback, cdnState)
    if not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkProjectsApi:GetProject(pid, function(data, err)
        if not data or type(data) ~= 'table' or not data.username or not data.world then
            return false
        end

        local username = data.username
        local world = data.world

        if not world.id or not world.projectId or not world.commitId then
            return false
        end

        if not commitId then
            commitId = world.commitId
        end

        GitService:GetContentWithRaw(
            world.worldName,
            username,
            filename,
            commitId,
            function(content, err)
                if callback and type(callback) == 'function' then
                    callback(content)
                end
            end,
            cdnState
        )
    end)
end

-- set world instance by pid 
function KeepworkServiceWorld:SetWorldInstanceByPid(pid, callback)
    self:GetWorldByProjectId(pid, function(data, err)
        if type(data) ~= 'table' or not data.worldName then
            return false
        end

        local foldername = data.worldName
        local worldpath = Mod.WorldShare.Utils.GetWorldFolderFullPath() .. "/" .. commonlib.Encoding.Utf8ToDefault(foldername)
        local status

        if not ParaIO.DoesFileExist(worldpath) then
            status = 2
        else
            if LocalService:IsZip(worldpath) then
                return false
            end
        end

        local worldRevision = WorldRevision:new():init(worldpath):Checkout()

        if not data.revision then
            return false
        end

        if tonumber(data.revision) == worldRevision then
            status = 3
        else
            if tonumber(data.revision) > worldRevision then
                status = 4
            else
                status = 5
            end
        end

        local worldTag = LocalService:GetTag(worldpath)

        local local_tagname

        if worldTag.local_tagname then
            local_tagname = worldTag.local_tagname
        else
            local_tagname = worldTag.name
        end


        local shared = false

        if KeepworkServiceSession:IsSignedIn() then
            local userId = Mod.WorldShare.Store:Get('user/userId')

            if data.user.id ~= 0 and tonumber(data.user.id) ~= (userId) then
                shared = true
            end
        end

        local currentWorld = self:GenerateWorldInstance({
            kpProjectId = pid,
            fromProjectId = data.fromProjectId,
            IsFolder = true,
            is_zip = false,
            Title = foldername,
            text = foldername,
            foldername = foldername,
            worldpath = worldpath,
            status = status,
            revision = data.revision,
            size = data.fileSize,
            modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(data.updatedAt),
            lastCommitId = data.commitId, 
            project = data.project,
            user = {
                id = data.userId,
                username = data.username,
            },
            local_tagname = local_tagname,
            remote_tagname =  data.extra.worldTagName,
            shared = shared,
            communityWorld = worldTag.communityWorld == 'true' or worldTag.communityWorld == true,
            isVipWorld = worldTag.isVipWorld == 'true' or worldTag.isVipWorld == true,
            instituteVipEnabled =  worldTag.instituteVipEnabled == 'true' or worldTag.instituteVipEnabled == true,
            memberCount = data.memberCount,
            members = {}
        })

        Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)

        if callback and type(callback) == 'function' then
            callback()
        end
    end)
end

-- get world list
function KeepworkServiceWorld:GetWorldsList(callback)
    if not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkWorldsApi:GetWorldList(10000, 1, callback)
end

-- get world by worldname
function KeepworkServiceWorld:GetWorld(foldername, shared, callback)
    if type(callback) ~= 'function' then
        return false
    end

    if type(foldername) ~= 'string' or not KeepworkService:IsSignedIn() then
        return false
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld') or {}

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if type(data) ~= 'table' then
            return false
        end

        for key, item in ipairs(data) do
            local localShared = string.match(currentWorld.worldpath or '', 'shared') == 'shared' and true or false

            if not localShared and not currentWorld.shared then
                callback(item)
            else
                if not currentWorld.shared then
                    -- illegal operation
                    return
                end

                local shared = false

                if item.user and item.project.memberCount > 1 then
                    shared = true
                end

                if currentWorld.user.id == item.user.id and
                   currentWorld.shared == shared then
                    -- exist
                    callback(item)
                    return
                end
            end
        end

        callback(false)
    end)
end

-- updat world info
function KeepworkServiceWorld:PushWorld(params, shared, callback)
    if type(params) ~= 'table' or
       not params.worldName or
       not KeepworkService:IsSignedIn() then
        return false
    end

    self:GetWorld(
        params.worldName or '',
        shared,
        function(world)
            local worldId = world and world.id or false

            if not worldId then
                return false
            end

            KeepworkWorldsApi:UpdateWorldInfo(worldId, params, callback)
        end
    )
end

-- get world by project id
function KeepworkServiceWorld:GetWorldByProjectId(kpProjectId, callback)
    if type(kpProjectId) ~= 'number' or kpProjectId == 0 then
        return false
    end

    KeepworkProjectsApi:GetProject(kpProjectId, function(data, err)
        if type(callback) ~= 'function' then
            return false
        end

        if err ~= 200 or not data or not data.world then
            callback(nil, err)
            return false
        end

        callback(data.world, err)
    end)
end

function KeepworkServiceWorld:GetLockInfo(pid, callback)
    if type(callback) ~= 'function' then
        return false
    end

    KeepworkWorldLocksApi:GetWorldLockInfo(
        pid,
        function(data, err)
            callback(data)
        end,
        function(data, err)
            callback(nil)
        end
    )
end

-- update project lock info
function KeepworkServiceWorld:UpdateLock(pid, mode, revision, server, password, callback)
    self.isLockFetching = true
    KeepworkWorldLocksApi:UpdateWorldLockRecord(
        pid,
        mode,
        revision,
        server,
        password,
        function(data, err)
            self.isLockFetching = false
            if type(callback) == 'function' then
                callback(data)
            end
        end,
        function()
            self.isLockFetching = false
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function KeepworkServiceWorld:UpdateLockHeartbeatStart(pid, mode, revision, server, password)
    if self.isUnlockFetching or self.lockHeartbeat then
        Mod.WorldShare.Utils.SetTimeOut(function()
            self:UpdateLockHeartbeatStart(pid, mode, revision, server, password)
        end, 3000)
        return false
    end

    self.lockHeartbeat = true
    local lockTime = 0

    local function Heartbeat()
        if lockTime == 0 then
            self:UpdateLock(
                pid,
                mode,
                revision,
                server,
                password,
                function(result)
                if self.lockHeartbeat then
                    lockTime = lockTime + 1
                    Heartbeat()
                end
            end)
            return true
        end

        Mod.WorldShare.Utils.SetTimeOut(function()
            if self.lockHeartbeat then
                lockTime = lockTime + 1

                if lockTime == 30 then
                    lockTime = 0
                end

                Heartbeat()
            end
        end, 1000)
    end

    Heartbeat()
end

function KeepworkServiceWorld:UnlockWorld(callback)
    self.lockHeartbeat = false
    local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

    if currentEnterWorld then
        if (currentEnterWorld.project and currentEnterWorld.project.memberCount or 0) > 1 then
            self.isUnlockFetching = true

            local function unlock()
                if self.isLockFetching then
                    Mod.WorldShare.Utils.SetTimeOut(function()
                        unlock()
                    end, 3000)
                    return false
                end

                KeepworkWorldLocksApi:RemoveWorldLockRecord(
                    currentEnterWorld.kpProjectId,
                    function()
                        self.isUnlockFetching = false

                        if type(callback) == 'function' then
                            callback()
                        end
                    end,
                    function()
                        self.isUnlockFetching = false

                        if type(callback) == 'function' then
                            callback()
                        end
                    end
                )
            end

            unlock()
        end
    end
end

function KeepworkServiceWorld:MergeRemoteWorldList(localWorlds, callback)
    if type(callback) ~= 'function' then
        return false
    end

    localWorlds = localWorlds or {}
    local userId = Mod.WorldShare.Store:Get('user/userId')

    self:GetWorldsList(function(data, err)
        if type(data) ~= "table" then
            return false
        end

        local remoteWorldsList = data
        local currentWorldList = commonlib.vector:new()
        local currentWorld

        -- handle both/network newest/local newest/network only worlds
        for DKey, DItem in ipairs(remoteWorldsList) do
            local isExist = false
            local text = DItem.worldName or ""
            local worldpath = ""
            local localTagname = ""
            local remoteTagname = ""
            local revision = 0
            local commitId = ""
            local remoteWorldUserId = DItem.user and DItem.user.id and tonumber(DItem.user.id) or 0
            local status
            local remoteShared = false
            local isVipWorld
            local instituteVipEnabled

            if remoteWorldUserId ~= 0 and tonumber(remoteWorldUserId) ~= (userId) then
                remoteShared = true
            end

            for LKey, LItem in ipairs(localWorlds) do
                if DItem.worldName == LItem.foldername and
                   remoteShared == LItem.shared and
                   not LItem.is_zip then
                    local function Handle()
                        if tonumber(LItem.revision or 0) == tonumber(DItem.revision or 0) then
                            status = 3 -- both
                            revision = LItem.revision
                        elseif tonumber(LItem.revision or 0) > tonumber(DItem.revision or 0) then
                            status = 4 -- network newest
                            revision = DItem.revision -- use remote revision beacause remote is newest
                        elseif tonumber(LItem.revision or 0) < tonumber(DItem.revision or 0) then
                            status = 5 -- local newest
                            revision = LItem.revision or 0
                        end
    
                        isExist = true

                        worldpath = LItem.worldpath
                        localTagname = LItem.local_tagname or LItem.foldername
                        remoteTagname = DItem.extra and DItem.extra.worldTagName or DItem.worldName
                        isVipWorld = LItem.isVipWorld
                        instituteVipEnabled = LItem.instituteVipEnabled
    
                        -- update project id for different user
                        if tonumber(LItem.kpProjectId) ~= tonumber(DItem.projectId) then
                            local tag = SaveWorldHandler:new():Init(worldpath):LoadWorldInfo()
    
                            tag.kpProjectId = DItem.projectId
                            LocalService:SetTag(worldpath, tag)
                        end
                    end

                    if remoteShared then
                        -- avoid upload same name share world
                        local sharedUsername = Mod.WorldShare:GetWorldData("username", LItem.worldpath)
                        if sharedUsername == DItem.user.username then
                            Handle()
                            break
                        end
                    else
                        Handle()
                        break
                    end
                end
            end

            if not isExist then
                --network only
                status = 2
                revision = DItem.revision
                remoteTagname = DItem.extra and DItem.extra.worldTagName or text

                if remoteTagname ~= "" and text ~= remoteTagname then
                    text = remoteTagname .. '(' .. text .. ')'
                end

                if remoteWorldUserId ~= 0 and remoteWorldUserId ~= tonumber(userId) then
                    -- shared world path
                    worldpath = format(
                        "%s/_shared/%s/%s/",
                        Mod.WorldShare.Utils.GetWorldFolderFullPath(),
                        DItem.user.username,
                        commonlib.Encoding.Utf8ToDefault(DItem.worldName)
                    )
                else
                    -- mine world path
                    worldpath = format(
                        "%s/%s/",
                        Mod.WorldShare.Utils.GetWorldFolderFullPath(),
                        commonlib.Encoding.Utf8ToDefault(DItem.worldName)
                    )
                end
            end

            -- shared world text
            if remoteShared then
                if DItem.extra and DItem.extra.worldTagName then
                    text = (DItem.user and DItem.user.username or '') .. '/' .. (DItem.extra and DItem.extra.worldTagName or '') .. '(' .. text .. ')'
                else
                    text = (DItem.user and DItem.user.username or '') .. '/' .. text
                end
            end

            if DItem.project then
                if DItem.project.visibility == 0 then
                    DItem.project.visibility = 0
                else
                    DItem.project.visibility = 1
                end
            end

            currentWorld = self:GenerateWorldInstance({
                Title = text,
                text = text,
                foldername = DItem.worldName,
                revision = revision,
                size = DItem.fileSize,
                modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(DItem.updatedAt),
                lastCommitId = DItem.commitId, 
                worldpath = worldpath,
                status = status,
                project = DItem.project,
                user = {
                    id = DItem.user.userId,
                    username = DItem.user.username,
                },
                kpProjectId = DItem.projectId,
                fromProjectId = DItem.fromProjectId,
                local_tagname = localTagname,
                remote_tagname = remoteTagname,
                IsFolder = true,
                is_zip = false,
                shared = remoteShared,
                isVipWorld = isVipWorld or false,
                instituteVipEnabled = instituteVipEnabled or false,
                memberCount = DItem.memberCount,
                members = {}
            })

            currentWorldList:push_back(currentWorld)
        end

        -- handle local only world
        for LKey, LItem in ipairs(localWorlds) do
            local isExist = false

            for DKey, DItem in ipairs(remoteWorldsList) do
                local remoteWorldUserId = DItem.user and DItem.user.id and tonumber(DItem.user.id) or 0
                local remoteShared = false

                if remoteWorldUserId ~= 0 and tonumber(remoteWorldUserId) ~= (userId) then
                    remoteShared = true
                end

                if LItem.foldername == DItem.worldName and
                   LItem.shared == remoteShared and
                   not LItem.is_zip then
                    isExist = true
                    break
                end
            end

            if not isExist then
                currentWorld = LocalServiceWorld:GenerateWorldInstance(LItem)

                currentWorldList:push_back(currentWorld)
            end
        end

        callback(currentWorldList)
    end)
end

function KeepworkServiceWorld:GenerateWorldInstance(params)
    if not params or type(params) ~= 'table' then
        return {}
    end

    return {
        Title = params.Title or '',
        text = params.text or '',
        foldername = params.foldername or '',
        revision = params.revision or 0,
        size = params.size or 0,
        modifyTime = params.modifyTime or '',
        lastCommitId = params.lastCommitId or '', 
        worldpath = params.worldpath or '',
        remotefile = format("local://%s", (params.worldpath or '')),
        status = params.status or 0,
        project = params.project or {},
        user = params.user or {}, -- { id = xxxx, username = xxxx }
        kpProjectId = params.kpProjectId and tonumber(params.kpProjectId) or 0,
        fromProjectId = params.fromProjectId and tonumber(params.fromProjectId) or 0,
        hasPid = params.kpProjectId and params.kpProjectId ~= 0 and true or false,
        local_tagname = params.local_tagname or '',
        remote_tagname = params.remote_tagname or '',
        IsFolder = params.IsFolder == 'true' or params.IsFolder == true,
        is_zip = params.is_zip == 'true' or params.is_zip == true,
        shared = params.shared or false,
        communityWorld = params.communityWorld or false,
        isVipWorld = params.isVipWorld or false,
        instituteVipEnabled = params.instituteVipEnabled or false,
        memberCount = params.memberCount or 0,
        members = params.members or {},
    }
end