--[[
Title: KeepworkService World
Author(s): big
CreateDate: 2019.12.09
ModifyDate: 2022.7.5
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
------------------------------------------------------------
]]

-- lib
local WorldRevision = commonlib.gettable('MyCompany.Aries.Creator.Game.WorldRevision')
local SaveWorldHandler = commonlib.gettable('MyCompany.Aries.Game.SaveWorldHandler')

-- service
local KeepworkService = NPL.load('../KeepworkService.lua')
local KeepworkServiceSession = NPL.load('./Session.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')

-- api
local KeepworkWorldsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Worlds.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Projects.lua')
local KeepworkWorldLocksApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/WorldLocks.lua')

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
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    self:GetWorldByProjectId(pid, function(data, err)
        if type(data) ~= 'table' or not data.worldName then
            return false
        end

        local foldername = data.worldName
        local sharedFolder = false
        local shared = false
        local userId = Mod.WorldShare.Store:Get('user/userId')
        local worldPath = ''

        if data.userId and tonumber(data.userId) ~= (userId) then
            sharedFolder = true
        end

        if sharedFolder then
            worldPath = format(
                '%s/_shared/%s/%s/',
                LocalServiceWorld:GetDefaultSaveWorldPath(),
                data.username,
                commonlib.Encoding.Utf8ToDefault(DItem.worldName)
            )
        else
            worldPath = format(
                '%s/%s/',
                LocalServiceWorld:GetUserFolderPath(),
                commonlib.Encoding.Utf8ToDefault(DItem.worldName)
            )
        end

        if data and data.memberCount > 1 then
            shared = true
        end

        if LocalService:IsZip(worldPath) then
            return
        end

        Compare:Init(worldPath, function(result, code)
            local currentWorld = self:GenerateWorldInstance({
                kpProjectId = pid,
                fromProjectId = data.fromProjectId,
                parentProjectId = data.parentProjectId,
                IsFolder = true,
                is_zip = false,
                text = foldername,
                name = foldername,
                foldername = foldername,
                worldpath = worldPath,
                status = code,
                revision = data.revision,
                size = data.fileSize,
                modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(data.updatedAt),
                lastCommitId = data.commitId,
                project = data.project,
                user = {
                    id = data.userId,
                    username = data.username,
                },
                shared = shared,
                communityWorld = data.extra.communityWorld,
                isVipWorld = data.extra.isVipWorld,
                instituteVipEnabled =  data.extra.instituteVipEnabled,
                memberCount = data.memberCount,
                members = {},
                level = data.level,
            })

            Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

            if callback and type(callback) == 'function' then
                callback()
            end
        end)
    end)
end

-- get world list
function KeepworkServiceWorld:GetWorldsList(callback)
    if not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkWorldsApi:GetWorldList(10000, 1, callback)
end

-- get my create world by world name
function KeepworkServiceWorld:GetMyWorldByWorldName(foldername, callback)
    local userId = Mod.WorldShare.Store:Get('user/userId')

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if type(data) ~= 'table' then
            if callback and type(callback) == 'function' then
                callback(false)    
            end
            return
        end

        for key, item in ipairs(data) do
            if userId == item.user.id then
                -- exist
                if callback and type(callback) == 'function' then
                    callback(item)    
                end
                return
            end
        end

        if callback and type(callback) == 'function' then
            callback(false)    
        end
    end)
end

-- only for create world page sync and rename feature
-- this is a filter for world list
function KeepworkServiceWorld:GetWorld(foldername, shared, worldUserId, callback)
    if not foldername or
       shared == nil or
       not worldUserId or
       not callback or
       type(callback) ~= 'function' then
        return false
    end

    if not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if type(data) ~= 'table' then
            return
        end

        for key, item in ipairs(data) do
            if not shared then
                if item.project.memberCount <= 1 then
                    callback(item)
                    return
                end
            else
                if (item.project.memberCount > 1 or item.project.managed == 1) and
                   worldUserId == item.user.id then
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
function KeepworkServiceWorld:PushWorld(worldId, params, callback)
    if params and
       type(params) ~= 'table' or
       not worldId or
       not KeepworkService:IsSignedIn() then
        return
    end

    KeepworkWorldsApi:UpdateWorldInfo(worldId, params, callback)
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

        -- for set instance by id
        data.world.memberCount = data.memberCount
        data.world.username = data.username

        callback(data.world, err)
    end)
end

function KeepworkServiceWorld:GetLockInfo(pid, callback)
    if type(callback) ~= 'function' then
        return
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
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentEnterWorld.members then
        return
    end

    if currentEnterWorld then
        if Mod.WorldShare.Utils:IsSharedWorld(currentEnterWorld, true) then
            self.isUnlockFetching = true

            local username = Mod.WorldShare.Store:Get('user/username')
            local isExist = false

            for key, item in ipairs(currentEnterWorld.members) do
                if item == username then
                    isExist = true
                end
            end

            if not isExist then
                self.isUnlockFetching = false

                if callback and type(callback) == 'function' then
                    callback(false)
                end

                return
            end

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
                            callback(true)
                        end
                    end,
                    function()
                        self.isUnlockFetching = false

                        if type(callback) == 'function' then
                            callback(false)
                        end
                    end
                )
            end

            unlock()
        end
    end
end

function KeepworkServiceWorld:MergeRemoteWorldList(localWorlds, callback)
    if not callback and type(callback) ~= 'function' then
        return
    end

    localWorlds = localWorlds or {}
    local userId = Mod.WorldShare.Store:Get('user/userId')
    local username = Mod.WorldShare.Store:Get('user/username')
    local syncBackUpWorld = {}

    if ParaIO.DoesFileExist('temp/sync_backup_world') then
        syncBackUpWorld = commonlib.Files.Find({}, 'temp/sync_backup_world', 0, 10000, '*')
    end

    self:GetWorldsList(function(remoteWorldsList, err)
        if not remoteWorldsList or type(remoteWorldsList) ~= 'table' then
            return
        end

        local currentWorldList = commonlib.vector:new()
        local currentWorld

        -- handle both/network newest/local newest/network only worlds
        for DKey, DItem in ipairs(remoteWorldsList) do
            local isExist = false
            local text = DItem.worldName or ''
            local worldpath = ''
            local revision = 0
            local commitId = ''
            local remoteWorldUserId = DItem.user and DItem.user.id and tonumber(DItem.user.id) or 0
            local status
            local remoteShared = false
            local isVipWorld
            local instituteVipEnabled
            local name = ''

            if DItem.extra and DItem.extra.worldTagName then
                text = DItem.extra.worldTagName
            end

            if DItem.project.managed == 1 then
                remoteShared = true
            else
                if DItem.project and DItem.project.memberCount and DItem.project.memberCount > 1 then
                    remoteShared = true
                end
            end

            for LKey, LItem in ipairs(localWorlds) do
                if DItem.worldName == LItem.foldername and not LItem.is_zip then
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
                        isVipWorld = LItem.isVipWorld
                        instituteVipEnabled = LItem.instituteVipEnabled
                        name = LItem.name
    
                        -- update project for different user
                        if tonumber(LItem.kpProjectId) ~= tonumber(DItem.projectId) then
                            if not string.match(LItem.foldername, '_main$') and
                               not remoteShared then
                                Mod.WorldShare.worldpath = nil -- force update world data.
                                local curWorldUsername = Mod.WorldShare:GetWorldData('username', LItem.worldpath)
                                local backUpWorldPath
 
                                if curWorldUsername then
                                    backUpWorldPath =
                                        LocalServiceWorld:GetDefaultSaveWorldPath() ..
                                        '/_user/' ..
                                        curWorldUsername ..
                                        '/' ..
                                        commonlib.Encoding.Utf8ToDefault(LItem.foldername)
                                else
                                    backUpWorldPath =
                                        'temp/sync_backup_world/' ..
                                        commonlib.Encoding.Utf8ToDefault(LItem.foldername) ..
                                        '_' ..
                                        ParaMisc.md5(tostring(os.time()))
                                end

                                commonlib.Files.MoveFolder(LItem.worldpath, backUpWorldPath)

                                ParaIO.DeleteFile(LItem.worldpath)

                                status = 2
                                isExist = false
                            end
                        end
                    end

                    if LItem.shared then -- share folder
                        if remoteShared == LItem.shared then
                            -- avoid upload same name share world
                            local sharedUsername = Mod.WorldShare:GetWorldData('username', LItem.worldpath)
    
                            if sharedUsername == DItem.user.username then
                                Handle()
                            end
                        end
                    else -- personal folder
                        if remoteShared then
                            if remoteWorldUserId == tonumber(userId) then
                                Handle()
                            end
                        else
                            Handle()
                        end
                    end
                end
            end

            if not isExist then
                --network only
                status = 2
                revision = DItem.revision
                name = DItem.extra and DItem.extra.worldTagName or ''

                if remoteShared and remoteWorldUserId ~= tonumber(userId) then
                    -- shared world path
                    worldpath = format(
                        '%s/_shared/%s/%s/',
                        LocalServiceWorld:GetDefaultSaveWorldPath(),
                        DItem.user.username,
                        commonlib.Encoding.Utf8ToDefault(DItem.worldName)
                    )

                else
                    -- mine world path
                    worldpath = format(
                        '%s/%s/',
                        LocalServiceWorld:GetUserFolderPath(),
                        commonlib.Encoding.Utf8ToDefault(DItem.worldName)
                    )

                    local matchStr = '^' .. username .. '_(.+)'

                    for SKey, SItem in ipairs(syncBackUpWorld) do
                        if SItem.fileattr == 16 then
                            local matchFoldername = string.match(SItem.filename, matchStr)

                            if matchFoldername and
                               type(matchFoldername) == 'string' and
                               matchFoldername == DItem.worldName then
                                commonlib.Files.MoveFolder('temp/sync_backup_world/' .. SItem.filename, worldpath)

                                local curRevision = LocalService:GetRevision(worldpath)

                                if curRevision == tonumber(DItem.revision or 0) then
                                    status = 3 -- both
                                elseif curRevision > tonumber(DItem.revision or 0) then
                                    status = 4 -- network newest
                                elseif curRevision < tonumber(DItem.revision or 0) then
                                    status = 5 -- local newest
                                end

                                break
                            end
                        end
                    end
                end
            end

            -- shared world text
            if remoteShared and remoteWorldUserId ~= tonumber(userId) then
                if DItem.extra and DItem.extra.worldTagName then
                    text = (DItem.user and DItem.user.username or '') .. '/' .. (DItem.extra and DItem.extra.worldTagName or '')
                else
                    text = (DItem.user and DItem.user.username or '') .. '/' .. text
                end
            end

            -- recover share remark
            if not remoteShared then
                if DItem.extra and DItem.extra.worldTagName and
                   text ~= DItem.extra.worldTagName then
                    text = DItem.extra.worldTagName
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
                parentProjectId = DItem.project and DItem.project.parentProjectId or 0,
                IsFolder = true,
                is_zip = false,
                shared = remoteShared,
                isVipWorld = isVipWorld or false,
                instituteVipEnabled = instituteVipEnabled or false,
                memberCount = DItem.project.memberCount,
                members = {},
                name = name,
                level = DItem.level and DItem.level or 0,
                isSystemGroup = DItem.isSystemGroup or false,
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

                if not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
                    currentWorldList:push_back(currentWorld)
                end
            end
        end

        callback(currentWorldList)
    end)
end

--allowMax 保存的时候允许临界值（localWorldListCount==freeMaxWorldCount）
function KeepworkServiceWorld:LimitFreeUser(isShowUI, callback, allowMax)
    if not callback or type(callback) ~= 'function' then
        return
    end

    local localWorldList = LocalServiceWorld:GetWorldList()
    local localWorldListCount = #localWorldList

    if isShowUI == true then
        isShowUI = true
    else
        isShowUI = false
    end

    local freeMaxWorldCount = 2 --免费用户最多能创建几个本地世界（包含家园）

    if localWorldListCount > freeMaxWorldCount or (not allowMax and localWorldListCount == freeMaxWorldCount) then
        GameLogic.IsVip('UnlimitWorldsNumber', isShowUI, callback)
        return
    end

    self:GetWorldsList(function(data)
        if not data or type(data) ~= 'table' then
            return
        end

        local dataCount = #data

        if localWorldListCount > 0 then
            if dataCount > 0 then
                local totalCount = localWorldListCount
                for DKey, DItem in ipairs(data) do
                    local contain = false
                    for key, item in ipairs(localWorldList) do
                        if item.foldername == DItem.worldName then
                            contain = true
                        end
                    end
                    if not contain then 
                        totalCount = totalCount + 1
                    end
                end
                if totalCount > freeMaxWorldCount or (not allowMax and totalCount == freeMaxWorldCount) then
                    GameLogic.IsVip('UnlimitWorldsNumber', isShowUI, callback)
                else
                    callback(true)
                end
            else
                callback(true)
            end
        else
            if dataCount > freeMaxWorldCount or (not allowMax and dataCount == freeMaxWorldCount) then
                GameLogic.IsVip('UnlimitWorldsNumber', isShowUI, callback)
            else
                callback(true)
            end
        end
    end)
end

function KeepworkServiceWorld:OnCreateHomeWorld(worldPath, homeWorldName)
    KeepworkWorldsApi:GetWorldByName(
        homeWorldName,
        function(data, err)
            if not data or
               type(data) ~= 'table' or
               not data[1] or
               type(data[1]) ~= 'table' then
                return
            end

            local worldTag = LocalService:GetTag(worldPath)

            worldTag.kpProjectId = data[1].projectId

            LocalService:SetTag(worldPath, worldTag)
        end
    )
end

function KeepworkServiceWorld:GenerateWorldInstance(params)
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
        text = params.text or '',
        foldername = params.foldername or '',
        name = params.name or '',
        revision = params.revision or 0,
        size = params.size or 0,
        modifyTime = params.modifyTime or '',
        lastCommitId = params.lastCommitId or '', 
        worldpath = params.worldpath or '',
        remotefile = remotefile,
        status = params.status or 0,
        project = params.project or {},
        user = params.user or {}, -- { id = xxxx, username = xxxx }
        kpProjectId = params.kpProjectId and tonumber(params.kpProjectId) or 0,
        fromProjectId = params.fromProjectId and tonumber(params.fromProjectId) or 0,
        hasPid = params.kpProjectId and params.kpProjectId ~= 0 and true or false,
        IsFolder = params.IsFolder == 'true' or params.IsFolder == true,
        is_zip = params.is_zip == 'true' or params.is_zip == true,
        shared = params.shared or false,
        communityWorld = params.communityWorld or false,
        isVipWorld = params.isVipWorld or false,
        instituteVipEnabled = params.instituteVipEnabled or false,
        memberCount = params.memberCount or 0,
        members = params.members or {},
        parentProjectId = params.parentProjectId or 0,
        level = params.level or 0, -- Is the world readable. 1. read only, 2. read and write
        isSystemGroup = params.isSystemGroup or false, -- Is the world in system group.
    }
end
