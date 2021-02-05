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
            commitId = world
        end

        GitService:GetContentWithRaw(
            world.worldName,
            username,
            filename,
            world.commitId,
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

        local currentWorld = {
            kpProjectId = pid,
            IsFolder = true,
            is_zip = false,
            Title = foldername,
            text = foldername,
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
            status = status,
            kpProjectId = pid,
        }

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

    local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"))

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if type(data) ~= 'table' then
            return false
        end

        for key, item in ipairs(data) do
            if item.user and item.user.id == userId then
                -- remote world info mine
                if not shared then
                    callback(item)
                    return true
                end
            else
                -- remote world info shared
                local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

                if shared and item.user.username == currentWorld.user.username then
                    callback(item)
                    return true
                end
            end
        end

        callback()
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
            local worldpath = ""
            local remotefile = ""
            local localTagname = ""
            local remoteTagname = ""
            local revision = 0
            local commitId = ""
            local remoteWorldUserId = DItem["user"] and DItem["user"]["id"] and tonumber(DItem["user"]["id"]) or 0
            local status
            local remoteShared
            local vipEnabled = false
            local instituteVipEnabled =false

            if remoteWorldUserId ~= 0 and tonumber(remoteWorldUserId) ~= (userId) then
                remoteShared = true
            end

            for LKey, LItem in ipairs(localWorlds) do
                if DItem["worldName"] == LItem["foldername"] and
                   remoteShared == LItem["shared"] and
                   not LItem.is_zip then
                    local function Handle()
                        if tonumber(LItem["revision"] or 0) == tonumber(DItem["revision"] or 0) then
                            status = 3 -- both
                            revision = LItem['revision']
                        elseif tonumber(LItem["revision"] or 0) > tonumber(DItem["revision"] or 0) then
                            status = 4 -- network newest
                            revision = DItem['revision'] -- use remote revision beacause remote is newest
                        elseif tonumber(LItem["revision"] or 0) < tonumber(DItem["revision"] or 0) then
                            status = 5 -- local newest
                            revision = LItem['revision'] or 0
                        end
    
                        isExist = true
                        worldpath = LItem["worldpath"]
                        remotefile = "local://" .. worldpath
    
                        localTagname = LItem["local_tagname"] or LItem["foldername"]
                        remoteTagname = DItem["extra"] and DItem["extra"]["worldTagName"] or DItem["worldName"]
                        vipEnabled = LItem["vipEnabled"] or false
                        instituteVipEnabled = LItem["instituteVipEnabled"] or false
    
                        if tonumber(LItem["kpProjectId"]) ~= tonumber(DItem["projectId"]) then
                            local tag = SaveWorldHandler:new():Init(worldpath):LoadWorldInfo()
    
                            tag.kpProjectId = DItem['projectId']
                            LocalService:SetTag(worldpath, tag)
                        end
                    end

                    if remoteShared then
                        if LItem['user']['username'] == DItem['user']['username'] then
                            Handle()
                            break
                        end
                    else
                        Handle()
                        break
                    end
                end
            end

            local text = DItem["worldName"] or ""

            if not isExist then
                --network only
                status = 2
                revision = DItem['revision']
                remoteTagname = DItem['extra'] and DItem['extra']['worldTagName'] or text

                if remoteTagname ~= "" and text ~= remoteTagname then
                    text = remoteTagname .. '(' .. text .. ')'
                end

                -- shared world path
                if remoteWorldUserId ~= 0 and remoteWorldUserId ~= tonumber(userId) then
                    worldpath = format(
                        "%s/_shared/%s/%s/",
                        Mod.WorldShare.Utils.GetWorldFolderFullPath(),
                        DItem["user"]["username"],
                        commonlib.Encoding.Utf8ToDefault(DItem["worldName"])
                    )
                else
                    worldpath = format(
                        "%s/%s/",
                        Mod.WorldShare.Utils.GetWorldFolderFullPath(),
                        commonlib.Encoding.Utf8ToDefault(DItem["worldName"])
                    )
                end

                remotefile = "local://" .. worldpath
            end

            -- shared world text
            if remoteShared then
                if DItem['extra'] and DItem['extra']['worldTagName'] then
                    text = (DItem['user'] and DItem['user']['username'] or '') .. '/' .. (DItem['extra'] and DItem['extra']['worldTagName'] or '') .. '(' .. text .. ')'
                else
                    text = (DItem['user'] and DItem['user']['username'] or '') .. '/' .. text
                end
            end

            currentWorld = {
                text = text,
                foldername = DItem["worldName"],
                revision = revision,
                size = DItem["fileSize"],
                modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(DItem["updatedAt"]),
                lastCommitId = DItem["commitId"], 
                worldpath = worldpath,
                remotefile = remotefile,
                status = status,
                project = DItem["project"] or {},
                user = DItem["user"] or {},
                kpProjectId = DItem["projectId"],
                hasPid = true,
                local_tagname = localTagname,
                remote_tagname = remoteTagname,
                is_zip = false,
                shared = remoteShared,
                vipEnabled = vipEnabled,
                instituteVipEnabled = instituteVipEnabled
            }

            if currentWorld.project.visibility == 0 then
                currentWorld.project.visibility = 0
            else
                currentWorld.project.visibility = 1
            end

            currentWorldList:push_back(currentWorld)
        end

        -- handle local only world
        for LKey, LItem in ipairs(localWorlds) do
            local isExist = false

            for DKey, DItem in ipairs(remoteWorldsList) do
                local remoteWorldUserId = DItem["user"] and DItem["user"]["id"] and tonumber(DItem["user"]["id"]) or 0
                local remoteShared

                if remoteWorldUserId ~= 0 and tonumber(remoteWorldUserId) ~= (userId) then
                    remoteShared = true
                end

                if LItem["foldername"] == DItem["worldName"] and
                   LItem["shared"] == remoteShared and
                   not LItem.is_zip then
                    isExist = true
                    break
                end
            end

            if not isExist then
                currentWorld = LItem
                currentWorld.modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(currentWorld.writedate)
                currentWorld.text = currentWorld.text
                currentWorld.local_tagname = LItem['local_tagname']
                currentWorld.status = 1 --local only
                currentWorld.is_zip = LItem['is_zip'] or false
                currentWorld.project = { visibility = 0 }

                currentWorldList:push_back(currentWorld)
            end
        end

        callback(currentWorldList)
    end)
end
