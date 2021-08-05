--[[
Title: Common Load World
Author(s): big
Date: 2021.1.20
City: Foshan
use the lib:
------------------------------------------------------------
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
------------------------------------------------------------
]]

-- libs
local Game = commonlib.gettable("MyCompany.Aries.Game")
local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')
local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')
local InternetLoadWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.InternetLoadWorld')
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

-- service
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local WorldKeyDecodePage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyDecodePage.lua')

-- databse
local CacheProjectId = NPL.load('(gl)Mod/WorldShare/database/CacheProjectId.lua')

-- api
local KeepworkBaseApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua")

local CommonLoadWorld = NPL.export()

function CommonLoadWorld:EnterCommunityWorld()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end
    local IsSummerUser = Mod.WorldShare.Utils.IsSummerUser()
    if KeepworkServiceSession:GetUserWhere() == 'HOME' then
        if IsSummerUser then
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('homeWorldId')))
    elseif KeepworkServiceSession:GetUserWhere() == 'SCHOOL' then
        if IsSummerUser then
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('schoolWorldId')))
    else
        CommonLoadWorld:SelectPlaceAndEnterCommunityWorld()
    end
end

function CommonLoadWorld:SelectPlaceAndEnterCommunityWorld()
    local IsSummerUser = Mod.WorldShare.Utils.IsSummerUser()
    MainLogin:ShowWhere(function(result)
        if result == 'HOME' then
            if IsSummerUser then
                GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
                return 
            end
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('homeWorldId')))
        elseif result == 'SCHOOL' then
            if IsSummerUser then
                GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
                return 
            end
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('schoolWorldId')))
        end
    end)
end

function CommonLoadWorld:EnterCourseWorld(aiCourseId, preRelease, releaseId)
    if not aiCourseId or type(preRelease) ~= 'boolean' or not releaseId then
        return
    end

    preRelease = preRelease == true and 'true' or 'false'

    local url = format(
        '%s/ai/courses/download?preRelease=%s&aiCourseId=%s&releaseId=%s',
        KeepworkBaseApi:GetCdnApi(),
        preRelease,
        aiCourseId,
        releaseId
    )

    Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

    local function LoadWorld(world, refreshMode)
        if world then
            if refreshMode == 'never' then
                if not LocalService:IsFileExistInZip(world:GetLocalFileName(), ":worldconfig.txt") then
                    refreshMode = 'force'
                end
            end

            local url = world:GetLocalFileName()
            DownloadWorld.ShowPage(url)
            InternetLoadWorld.LoadWorld(
                world,
                nil,
                refreshMode,
                function(bSucceed, localWorldPath)
                    DownloadWorld.Close()
                end
            )
        end
    end

    local world = RemoteWorld.LoadFromHref(url, 'self')
    local token = Mod.WorldShare.Store:Get('user/token')

    if token then
        world:SetHttpHeaders({Authorization = format("Bearer %s", token)})
    end

    local fileUrl = world:GetLocalFileName()

    if ParaIO.DoesFileExist(fileUrl) then
        LoadWorld(world, 'never')
    else
        LoadWorld(world, 'force')
    end
end

function CommonLoadWorld:EnterHomeworkWorld(aiHomeworkId, preRelease, releaseId)
    if not aiHomeworkId or type(preRelease) ~= 'boolean' or not releaseId then
        return
    end

    preRelease = preRelease == true and 'true' or 'false'

    local url = format(
        '%s/ai/homeworks/download?preRelease=%s&aiHomeworkId=%s&releaseId=%s',
        KeepworkBaseApi:GetCdnApi(),
        preRelease,
        aiHomeworkId,
        releaseId
    )

    Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

    local function LoadWorld(world, refreshMode)
        if world then
            if refreshMode == 'never' then
                if not LocalService:IsFileExistInZip(world:GetLocalFileName(), ":worldconfig.txt") then
                    refreshMode = 'force'
                end
            end

            local url = world:GetLocalFileName()
            DownloadWorld.ShowPage(url)
            InternetLoadWorld.LoadWorld(
                world,
                nil,
                refreshMode,
                function(bSucceed, localWorldPath)
                    DownloadWorld.Close()
                end
            )
        end
    end

    local world = RemoteWorld.LoadFromHref(url, 'self')
    local token = Mod.WorldShare.Store:Get('user/token')

    if token then
        world:SetHttpHeaders({Authorization = format("Bearer %s", token)})
    end

    local fileUrl = world:GetLocalFileName()

    if ParaIO.DoesFileExist(fileUrl) then
        LoadWorld(world, 'never')
    else
        LoadWorld(world, 'force')
    end
end

function CommonLoadWorld:EnterCacheWorldById(pid)
    pid = tonumber(pid)

    local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

    if not cacheWorldInfo or not cacheWorldInfo.worldInfo or not cacheWorldInfo.worldInfo.archiveUrl then
        return false
    end

    local worldInfo = cacheWorldInfo.worldInfo
    local url = cacheWorldInfo.worldInfo.archiveUrl
    local world = RemoteWorld.LoadFromHref(url, "self")
    world:SetProjectId(pid)
    local fileUrl = world:GetLocalFileName()

    if fileUrl then
        WorldCommon.OpenWorld(fileUrl, true)
    else
        _guihelper.MessageBox(L"无效的世界文件")
    end
end

function CommonLoadWorld:EnterWorldById(pid, refreshMode, failed)
    if not pid then
        return false
    end

    pid = tonumber(pid)

    local world
    local overtimeEnter = false
    local fetchSuccess = false
    local tryTimes = 0

    local function HandleLoadWorld(url, worldInfo, offlineMode)
        if not url then
            return false
        end

        if overtimeEnter and Mod.WorldShare.Store:Get('world/isEnterWorld') then
            return false
        end

        local function LoadWorld(world, refreshMode)
            if world then
                -- encrypt mode load world
                if self.encryptWorldMode then
                    local localWorldFile = world:GetLocalFileName() or ''
                    local encryptWorldFile = string.match(localWorldFile, '(.+)%.zip$') .. '.pkg'

                    local encryptWorldFileExist = false

                    if ParaIO.DoesFileExist(encryptWorldFile) then
                        encryptWorldFileExist = true     
                    end

                    -- TODO: never and auto
                    Game.Start(encryptWorldFile)

                    if not encryptWorldFileExist or
                       refreshMode == 'force' then
                        if ParaIO.DoesFileExist(encryptWorldFile) then
                            ParaIO.DeleteFile(encryptWorldFile)    
                        end

                        if ParaIO.DoesFileExist(localWorldFile) then
                            ParaIO.DeleteFile(localWorldFile)
                        end

                        DownloadWorld.ShowPage(url)

                        world:DownloadRemoteFile(function(bSucceed, msg)
                            DownloadWorld.Close()

                            if bSucceed then
                                if not ParaIO.DoesFileExist(localWorldFile) then
                                    _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', pid))

                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', localWorldFile)

                                    return
                                end

                                ParaAsset.OpenArchive(localWorldFile, true)
                                
                                local output = {}

                                commonlib.Files.Find(output, "", 0, 500, ":worldconfig.txt", localWorldFile)

                                if #output == 0 then
                                    _guihelper.MessageBox(format(L'下载的世界已损坏，请重新尝试几次（项目ID：%d）', pid))

                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', localWorldFile)

                                    ParaIO.DeleteFile(localWorldFile)

                                    ParaAsset.CloseArchive(localWorldFile)

                                    return
                                end

                                ParaAsset.CloseArchive(localWorldFile)
    
                                LocalServiceWorld:EncryptWorld(localWorldFile, encryptWorldFile)
                                ParaIO.DeleteFile(localWorldFile)
                                Game.Start(encryptWorldFile)
                            else
                                if tryTimes > 0 then
                                    MainLogin:Close()

                                    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

                                    if not CreatePage then
                                        Create:Show()
                                    end
                                    return
                                end

                                local cdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(
                                                        worldInfo.worldName,
                                                        worldInfo.username,
                                                        worldInfo.commitId
                                                      )

                                HandleLoadWorld(cdnArchiveUrl, worldInfo)
                                tryTimes = tryTimes + 1
                            end
                        end)
                    end

                    return
                end

                -- zip mode load world
                if refreshMode == 'never' then
                    if not LocalService:IsFileExistInZip(world:GetLocalFileName(), ":worldconfig.txt") then
                        refreshMode = 'force'
                    end
                end

                DownloadWorld.ShowPage(url)

                local mytimer = commonlib.Timer:new(
                    {
                        callbackFunc = function(timer)
                            InternetLoadWorld.LoadWorld(
                                world,
                                nil,
                                refreshMode or 'auto',
                                function(bSucceed, localWorldPath)
                                    DownloadWorld.Close()

                                    if not bSucceed then
                                        if tryTimes > 0 then
                                            MainLogin:Close()
        
                                            local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')
        
                                            if not CreatePage then
                                                Create:Show()
                                            end
                                            return true -- always return true
                                        end

                                        local cdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(
                                                                worldInfo.worldName,
                                                                worldInfo.username,
                                                                worldInfo.commitId
                                                            )

                                        HandleLoadWorld(cdnArchiveUrl, worldInfo)
                                        tryTimes = tryTimes + 1
                                    else
                                        if not ParaIO.DoesFileExist(localWorldPath) then
                                            _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', pid))

                                            LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', localWorldPath)

                                            return true -- always return true
                                        end

                                        ParaAsset.OpenArchive(localWorldPath, true)
                                        
                                        local output = {}

                                        commonlib.Files.Find(output, "", 0, 500, ":worldconfig.txt", localWorldPath)

                                        if #output == 0 then
                                            _guihelper.MessageBox(format(L'下载的世界已损坏，请重新尝试几次（项目ID：%d）', pid))

                                            LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', localWorldPath)

                                            ParaIO.DeleteFile(localWorldPath)

                                            ParaAsset.CloseArchive(localWorldPath)

                                            return true
                                        end

                                        ParaAsset.CloseArchive(localWorldPath)

                                        Game.Start(localWorldPath)
                                    end

                                    return true -- use mod logic
                                end
                            )
                        end
                    }
                )

                -- prevent recursive calls.
                mytimer:Change(1, nil)
            else
                _guihelper.MessageBox(
                    format(L'无效的世界信息（项目ID：%d）', pid)
                )
            end
        end

        if url:match('^https?://') then
            world = RemoteWorld.LoadFromHref(url, 'self')
            world:SetProjectId(pid)

            local token = Mod.WorldShare.Store:Get('user/token')
            if token then
                world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
            end

            local fileUrl = world:GetLocalFileName()

            Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

            if ParaIO.DoesFileExist(fileUrl) then
                if offlineMode then
                    LoadWorld(world, 'never')
                    return
                end

                Mod.WorldShare.MsgBox:Wait()
                GitService:GetWorldRevision(pid, false, function(data, err)
                    local localRevision = tonumber(LocalService:GetZipRevision(fileUrl)) or 0
                    local remoteRevision = tonumber(data) or 0

                    Mod.WorldShare.MsgBox:Close()

                    if localRevision == 0 then
                        LoadWorld(world, 'auto')

                        return
                    end

                    if localRevision == remoteRevision then
                        LoadWorld(world, 'never')

                        return
                    end

					if refreshMode == 'force' then
						LoadWorld(world, refreshMode)
						return
					end

                    local worldName = ''

                    if worldInfo and worldInfo.extra and worldInfo.extra.worldTagName then
                        worldName = worldInfo.extra.worldTagName
                    else
                        worldName = worldInfo.worldName
                    end

                    local params = Mod.WorldShare.Utils.ShowWindow(
                        0,
                        0,
                        'Mod/WorldShare/cellar/Common/LoadWorld/ProjectIdEnter.html?project_id=' 
                            .. pid
                            .. '&remote_revision=' .. remoteRevision
                            .. '&local_revision=' .. localRevision
                            .. '&world_name=' .. worldName,
                        'ProjectIdEnter',
                        0,
                        0,
                        '_fi',
                        false
                    )

                    params._page.callback = function(data)
                        if data == 'local' then
                            LoadWorld(world, 'never')
                        elseif data == 'remote' then
                            LoadWorld(world, 'force')
                        end
                    end
                end)
            else
                LoadWorld(world, 'auto')
            end
        end
	end

    -- show view over 10 seconds
    Mod.WorldShare.Utils.SetTimeOut(function()
        if fetchSuccess then
            return false
        end

        MainLogin:Close()

        local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

        if not CreatePage then
            Create:Show()
        end

        Mod.WorldShare.MsgBox:Close()
    end, 10000)

    Mod.WorldShare.MsgBox:Wait(20000)

    KeepworkServiceProject:GetProject(
        pid,
        function(data, err)
            Mod.WorldShare.MsgBox:Close()
            fetchSuccess = true

            if err == 0 then
                local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

                if not cacheWorldInfo or not cacheWorldInfo.worldInfo then
                    GameLogic.AddBBS(nil, format(L'网络环境差，或离线中，请联网后再试（%d）', err), 3000, '255 0 0')
                    return
                end

                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                HandleLoadWorld(cacheWorldInfo.worldInfo.archiveUrl, cacheWorldInfo.worldInfo, true)

                return
            end

            if err == 404 or
               not data or
               not data.world or
               not data.world.archiveUrl or
               #data.world.archiveUrl == 0 then
                local archiveUrlLength = 0

                if data and data.world and data.world.archiveUrl then
                    archiveUrlLength = #data.world.archiveUrl
                end

                GameLogic.AddBBS(
                    nil,
                    format(L'未找到对应项目信息（项目ID：%d）（URL长度：%d）（ERR：%d）', pid, archiveUrlLength, err),
                    10000,
                    '255 0 0'
                )

                local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

                if not CreatePage then
                    Create:Show() -- use local mode instead of enter world
                end
                return
            end

            if err ~= 200 then
                GameLogic.AddBBS(nil, format(L'服务器维护中（%d）', err), 3000, '255 0 0')
                return
            end

            -- update world info
            data.world.username = data.username

            local archiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(
                                data.world.worldName,
                                data.world.username,
                                data.world.commitId
                               )

            local function ResetVerified()
                self.isVisiblityVerified = false
                self.vipVerified = false
                self.instituteVerified = false
                self.encodeWorldVerified = false
                self.encryptWorldVerified = false
            end

            local function HandleVerified()
                if data.visibility == 1 and
                   not self.isVisiblityVerified then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
                    else
                        KeepworkServiceProject:GetMembers(pid, function(members, err)
                            if type(members) ~= 'table' then
                                return
                            end
    
                            local username = Mod.WorldShare.Store:Get('user/username')
    
                            for key, item in ipairs(members) do
                                if item and item.username and item.username == username then    
                                    Mod.WorldShare.Store:Set('world/openKpProjectId', pid)

                                    data.world.archiveUrl = data.world.archiveUrl .. "&private=true"
                                    self.isVisiblityVerified = true

                                    HandleVerified()

                                    return
                                end
                            end

                            GameLogic.AddBBS(
                                nil,
                                format(L'您未获得该项目的访问权限（项目ID：%d）（用户名：%s）', pid or 0, username or ''),
                                3000,
                                '255 0 0'
                            )

                            ResetVerified()

                            return
                        end)
                    end

                    return
                end
    
                -- vip enter
                if not self.vipVerified and
                   data and
                   data.extra and
                   ((data.extra.vipEnabled and data.extra.vipEnabled == 1) or
                   (data.extra.isVipWorld and data.extra.isVipWorld == 1)) then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
                    else
                        local username = Mod.WorldShare.Store:Get('user/username')

                        if data.username and data.username ~= username then
                            GameLogic.IsVip('Vip', true, function(result)
                                if result then
                                    self.vipVerified = true
                                    HandleVerified()
                                else
                                    local username = Mod.WorldShare.Store:Get('user/username')

                                    _guihelper.MessageBox(
                                        format(L'你没有权限进入此世界（VIP）(项目ID：%d)（用户名：%s）', pid or 0, username or '')
                                    )

                                    ResetVerified()
                                end
                            end, 'Vip')
                        end
                    end
    
                    return
                end
    
                -- vip institute enter
                if data and
                   data.extra and
                   data.extra.instituteVipEnabled and
                   data.extra.instituteVipEnabled == 1 and
                   not self.instituteVerified then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
                        return
                    else
                        GameLogic.IsVip('IsOrgan', true, function(result)
                            if result then
                                self.instituteVerified = true
                                HandleVerified()
                            else
                                local username = Mod.WorldShare.Store:Get('user/username')

                                _guihelper.MessageBox(
                                    format(L'你没有权限进入此世界（机构VIP）(项目ID：%d)（用户名：%s）', pid or 0, username or '')
                                )

                                ResetVerified()
                            end
                        end, 'Institute')
                    end

                    return
                end

                -- encrypt world
                if data and
                   data.level and
                   data.level ~= 2 and
                   not self.encryptWorldVerified then
                    self.encryptWorldVerified = true
                    self.encryptWorldMode = true
                    HandleVerified()
                    return
                end

                -- encode world
                if data and
                   data.extra and
                   data.extra.encode_world == 1 and
                   not self.encodeWorldVerified then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
    
                        return
                    else
                        local username = Mod.WorldShare.Store:Get('user/username')
    
                        if data.username and data.username == username then
                            self.encodeWorldVerified = true
                            HandleVerified()
                        else
                            WorldKeyDecodePage.Show(data, function()
                                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                                HandleLoadWorld(archiveUrl, data.world)
                                CacheProjectId:SetProjectIdInfo(pid, data.world)
                            end)

                            ResetVerified()
                        end
                    end

                    return
                end

                ResetVerified()

                -- enter world
                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                HandleLoadWorld(archiveUrl, data.world)
                CacheProjectId:SetProjectIdInfo(pid, data.world)
            end

            HandleVerified()
        end
    )
end