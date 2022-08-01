--[[
Title: SyncWorld
Author(s): big
CreateDate: 2017.04.17
ModifyDate: 2022.7.1
Desc: 
use the lib:
------------------------------------------------------------
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
------------------------------------------------------------
]]

-- bottles
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local Progress = NPL.load('./Progress/Progress.lua')
local Permission = NPL.load('(gl)Mod/WorldShare/cellar/Permission/Permission.lua')

-- service
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local SyncToLocal = NPL.load('(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua')
local SyncToDataSource = NPL.load('(gl)Mod/WorldShare/service/SyncService/SyncToDataSource.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')

-- helper
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

-- libs
local WorldShare = commonlib.gettable('Mod.WorldShare')
local WorldRevision = commonlib.gettable('MyCompany.Aries.Creator.Game.WorldRevision')
local SaveWorldHandler = commonlib.gettable('MyCompany.Aries.Game.SaveWorldHandler')

local SyncWorld = NPL.export()

function SyncWorld:OnWorldLoad(callback)
    Compare:GetCurrentWorldInfo(function()
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

        if not currentEnterWorld.is_zip then
            Compare:CheckRevision(currentEnterWorld.worldpath)
        end

        if callback and type(callback) == 'function' then
            callback()
        end
    end)
end

function SyncWorld:ShowNewVersionFoundPage(callback)
    local params =
        SyncWorld:ShowDialog(
            'Mod/WorldShare/cellar/Sync/Theme/NewVersionFound.html',
            'Mod.WorldShare.Sync.NewVersionFound'
        )

    params._page.afterSyncCallback = callback
end

function SyncWorld:ShowStartSyncPage(useOffline, callback)
    local params = SyncWorld:ShowDialog(
        'Mod/WorldShare/cellar/Sync/Theme/StartSync.html?useOffline=' .. (useOffline and 'true' or 'false'),
        'Mod.WorldShare.Sync.StartSync'
    )

    params._page.afterSyncCallback = callback
end

function SyncWorld:CloseStartSyncPage()
    local StartSyncPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Sync.StartSync')

    if StartSyncPage then
        StartSyncPage:CloseWindow()
    end
end

function SyncWorld:ShowBeyondVolume(bEnabled)
    SyncWorld:ShowDialog(
        'Mod/WorldShare/cellar/Sync/Theme/BeyondVolume.html?bEnabled=' .. (bEnabled and 'true' or 'false'),
        'Mod.WorldShare.Sync.BeyondVolume'
    )
end

function SyncWorld:CloseBeyondVolumePage()
    local BeyondVolumePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Sync.BeyondVolume')

    if BeyondVolumePage then
        BeyondVolumePage:CloseWindow()
    end
end

function SyncWorld:ShowStartSyncUseLocalPage(callback)
    local params =
        SyncWorld:ShowDialog(
            'Mod/WorldShare/cellar/Sync/Theme/UseLocal.html',
            'Mod.WorldShare.Sync.UseLocal'
        )

    params._page.afterSyncCallback = callback
end

function SyncWorld:ShowStartSyncUseDataSourcePage(callback)
    local params =
        SyncWorld:ShowDialog(
            'Mod/WorldShare/cellar/Sync/Theme/UseDataSource.html',
            'Mod.WorldShare.Sync.UseDataSource'
        )

    params._page.afterSyncCallback = callback
end

function SyncWorld:ShowDialog(url, name)
    return Mod.WorldShare.Utils.ShowWindow(0, 0, url, name, 0, 0, '_fi', false)
end

function SyncWorld:BackupWorld()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    local revision = WorldRevision:new():init(currentWorld and currentWorld.worldpath)
    revision:Checkout()
    revision:Backup()
end

function SyncWorld:SyncToLocal(callback, _, noShownResult)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return
    end

    -- get latest commidId
    KeepworkServiceProject:GetProject(
        currentWorld.kpProjectId,
        function(data, err)
            if data and data.world and data.world.commitId then
                currentWorld.lastCommitId = data.world.commitId
            end

            Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

            local syncInstance = SyncToLocal:Init(function(result, option)
                if result == false then
                    if option and type(option) == 'string' then
                        Progress:ClosePage()

                        if option == 'NEWWORLD' then
                            GameLogic.AddBBS(nil, L'服务器未找到世界数据，请新建', 3000, '255 255 0')
                            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                            CreateWorld:CreateNewWorld(currentWorld.foldername)
                            return false
                        end
            
                        GameLogic.AddBBS(nil, option, 3000, '255 0 0')
                    end

                    if option and type(option) == 'table' then
                        if option.method == 'UPDATE-PROGRESS' then
                            Progress:UpdateDataBar(option.current, option.total, option.msg)
                            return false
                        end
        
                        if option.method == 'UPDATE-PROGRESS-FAIL' then
                            Progress:SetFinish(true)
                            Progress:ClosePage()
                            GameLogic.AddBBS(nil, option.msg, 3000, '255 0 0')
                            return false
                        end
        
                        if option.method == 'UPDATE-PROGRESS-FINISH' then
                            Progress:SetFinish(true)
                            Progress:UpdateDataBar(1, 1, L'处理完成')

                            if noShownResult then
                                if callback and type(callback) == 'function' then
                                    callback()
                                end
                            end
                            return false
                        end
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(result, option)
                end
            end)

            -- load sync progress UI
            Progress:Init(syncInstance)
        end,
        function()
            GameLogic.AddBBS(nil, L'获取项目信息失败', 3000, '255 0 0')
        end
    )
end

function SyncWorld:SyncToLocalSingle(callback)
    local syncInstance = SyncToLocal:Init(function(result, option)
        if result == false then
            if type(option) == 'string' then
                Progress:ClosePage()

                if option == 'NEWWORLD' then
                    if type(callback) == 'function' then
                        callback(result, option)
                    end
                    return false
                end
    
                GameLogic.AddBBS(nil, option, 3000, '255 0 0')
            end

            if type(option) == 'table' then
                if option.method == 'UPDATE-PROGRESS' then
                    Progress:UpdateDataBar(option.current, option.total, option.msg)
                    return false
                end

                if option.method == 'UPDATE-PROGRESS-FAIL' then
                    Progress:SetFinish(true)
                    Progress:ClosePage()
                    GameLogic.AddBBS(nil, option.msg, 3000, '255 0 0')
                    return false
                end

                if option.method == 'UPDATE-PROGRESS-FINISH' then
                    Progress:SetFinish(true)
                    Progress:UpdateDataBar(1, 1, L'处理完成')
                    return false
                end
            end
        end

        if callback and type(callback) == 'function' then
            callback(result, option)
        end
    end)

    -- load sync progress UI
    Progress:Init(syncInstance)
end

function SyncWorld:SyncToDataSourceByWorldName(worldName, callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    KeepworkServiceWorld:GetMyWorldByWorldName(worldName, function(data)        
        if data then
            KeepworkServiceWorld:SetWorldInstanceByPid(data.projectId, function()
                local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
                local worldTag = LocalService:GetTag(currentWorld.worldpath)

                if worldTag then
                    currentWorld.parentProjectId = worldTag.parentProjectId
                end

                local members = currentWorld.members or {}
                if currentWorld.memberCount and currentWorld.memberCount > 0 and #members == 0 then
                    KeepworkServiceProject:GetMembers(currentWorld.kpProjectId, function(membersData, err)
                        local members = {}
                        for key, item in ipairs(membersData) do
                            members[#members + 1] = item.username
                        end
                        currentWorld.members = members
                        Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

                        SyncWorld:SyncToDataSource(function(result)
                            if callback and type(callback) == 'function' then
                                callback(result, currentWorld.kpProjectId)
                            end
                        end)
                    end)
                else
                    Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

                    SyncWorld:SyncToDataSource(function(result)
                        if callback and type(callback) == 'function' then
                            callback(result, currentWorld.kpProjectId)
                        end
                    end)
                end
            end)
        else
            LocalServiceWorld:SetWorldInstanceByFoldername(worldName)
            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
            SyncWorld:SyncToDataSource(function(result)
                if callback and type(callback) == 'function' then
                    callback(result, currentWorld.kpProjectId)
                end
            end)
        end
    end)
end

function SyncWorld:SyncToDataSource(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    local function Handle(checkSizeResult)
        -- close the notice
        Mod.WorldShare.MsgBox:Close()

        if not checkSizeResult then
            return
        end

        if not currentWorld.worldpath or currentWorld.worldpath == '' then
            return
        end

        local syncInstance = SyncToDataSource:Init(function(result, option)
            if result == false then
                if option and type(option) == 'string' then
                    Progress:ClosePage()
    
                    if option == 'RE-ENTRY' then
                        GameLogic.AddBBS(nil, L'请重新登录', 3000, '255 0 0')
    
                        LoginModal:Init(function(result)
                            if result then
                                Mod.WorldShare.Utils.SetTimeOut(function()
                                    self:SyncToDataSource(callback)
                                end, 300)
                            else
                                Progress:ClosePage()
                            end
                        end)
    
                        return
                    end
    
                    GameLogic.AddBBS(nil, option, 3000, '255 0 0')
                end
    
                if option and type(option) == 'table' then
                    if option.method == 'UPDATE-PROGRESS' then
                        Progress:UpdateDataBar(option.current, option.total, option.msg)
                        return
                    end
    
                    if option.method == 'UPDATE-PROGRESS-FAIL' then
                        Progress:SetFinish(true)
                        Progress:ClosePage()
                        GameLogic.AddBBS(nil, option.msg, 3000, '255 0 0')
                        return
                    end
    
                    if option.method == 'UPDATE-PROGRESS-FINISH' then
                        Progress:SetFinish(true)
                        Progress:UpdateDataBar(1, 1, L'处理完成')
                        return
                    end
                end
            end

            if callback and type(callback) == 'function' then
                callback(result, option)
            end
        end)

        -- load sync progress UI
        Progress:Init(syncInstance)
    end

    Mod.WorldShare.MsgBox:Wait()

    KeepworkServiceWorld:GetWorldsList(function(data)
        if not data or type(data) ~= 'table' then
            return
        end

        local dataCount = #data

        if dataCount >= 3 then
            local isModify = false

            for key, item in ipairs(data) do
                if item.projectId == currentWorld.kpProjectId then
                    isModify = true
                end
            end

            if not isModify then
                GameLogic.IsVip('UnlimitWorldsNumber', true, function(result)
                    if result then
                        self:CheckWorldSize(Handle)
                    end
                end)
            else
                self:CheckWorldSize(Handle)
            end
        else
            self:CheckWorldSize(Handle)
        end
    end)
end

function SyncWorld:CheckTagName(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if currentWorld and currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
        Mod.WorldShare.MsgBox:Wait()
        KeepworkServiceProject:GetProject(currentWorld.kpProjectId, function(data)
            Mod.WorldShare.MsgBox:Close()

            local name = currentWorld.name and currentWorld.name or ''

            if data.extra and
            data.extra.worldTagName and
            data.extra.worldTagName ~= currentWorld.name then
                local params = Mod.WorldShare.Utils.ShowWindow(
                    630,
                    240,
                    'Mod/WorldShare/cellar/Sync/Theme/CheckTagName.html?remote_tagname=' ..
                        data.extra.worldTagName ..
                        '&local_tagname=' ..
                        name,
                    'Mod.WorldShare.Sync.CheckTagName'
                )

                params._page.callback = function(params)
                    if callback and type(callback) == 'function' then
                        callback(params, data.extra.worldTagName)
                    end
                end
            else
                if callback and type(callback) == 'function' then
                    callback('')
                end
            end
        end)
    else
        if callback and type(callback) == 'function' then
            callback('')
        end
    end
end

function SyncWorld.GetCurrentRevision()
    return tonumber(Mod.WorldShare.Store:Get('world/currentRevision')) or 0
end

function SyncWorld.GetRemoteRevision()
    return tonumber(Mod.WorldShare.Store:Get('world/remoteRevision')) or 0
end

function SyncWorld:GetCurrentRevisionInfo()
    WorldShare.worldData = nil
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    return WorldShare:GetWorldData('revision', currentWorld and currentWorld.worldpath .. '/')
end

function SyncWorld:CheckWorldSize(callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or not currentWorld.worldpath  or #currentWorld.worldpath == 0 then
        return false
    end

    local filesTotal = LocalService:GetWorldSize(currentWorld.worldpath)
    local maxSize = 0

    GameLogic.IsVip('LimitWorldSize20Mb', false, function(result20mb)
        Permission:CheckPermission('OnlineWorldData50Mb', false, function(result50mb)
            if filesTotal > 20 * 1024 * 1024 then
                if result20mb or result50mb then
                    if filesTotal > 50 * 1024 * 1024 then
                        self:ShowBeyondVolume(true)
                        callback(false)
                    else
                        callback(true)
                    end
                else
                    GameLogic.IsVip('LimitWorldSize20Mb', true)
                    self:ShowBeyondVolume(false)
                    callback(false)
                end
            else
                callback(true)
            end
        end)
    end)
end

function SyncWorld:GetWorldDateTable()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local date = {}

    if currentWorld and currentWorld.tooltip then
        for item in string.gmatch(currentWorld.tooltip, '[^:]+') do
            date[#date + 1] = item
        end

        date = date[1]
    else
        date = os.date('%Y-%m-%d-%H-%M-%S')
    end

    return date
end

function SyncWorld:CheckAndUpdatedBeforeEnterMyHome(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    local username = Mod.WorldShare.Store:Get('user/username')

    if not username then
        return false
    end

    local foldername = username .. '_main'

    self:CheckAndUpdatedByFoldername(foldername, callback)
end

function SyncWorld:CheckAndUpdatedByFoldername(folderName, callback)
    KeepworkServiceProject:GetProjectIdByWorldName(folderName, false, function(projectId)
        local worldPath =
            format(
                '%s/%s/',
                LocalServiceWorld:GetDefaultSaveWorldPath(),
                commonlib.Encoding.Utf8ToDefault(foldername)
            )

        if not ParaIO.DoesFileExist(worldPath) then
            worldPath =
                format(
                    '%s/%s/',
                    LocalServiceWorld:GetUserFolderPath(),
                    commonlib.Encoding.Utf8ToDefault(foldername)
                )
        end

        local worldTagPath = worldPath .. 'tag.xml'
        local worldTag = LocalService:GetTag(worldPath)

        if not ParaIO.DoesFileExist(worldTagPath) then
            return
        end

        if projectId and type(projectId) == 'number' then
            -- exist
            worldTag.kpProjectId = projectId
            LocalService:SetTag(worldPath, worldTag)

            KeepworkServiceWorld:SetWorldInstanceByPid(projectId, function()
                self:CheckAndUpdated(callback)
            end)
        else
            -- not exist
            worldTag.kpProjectId = 0
            LocalService:SetTag(worldPath, worldTag)

            LocalServiceWorld:SetWorldInstanceByFoldername(folderName)

            self:CheckAndUpdated(callback)
        end

    end)
end

function SyncWorld:CheckAndUpdated(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if currentWorld.status == 5 then
        self:ShowNewVersionFoundPage(callback)
    else
        if callback and type(callback) == 'function' then
            callback()
        end
    end
end
