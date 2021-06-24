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
local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')
local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')
local InternetLoadWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.InternetLoadWorld')
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

-- service
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')

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

    local function HandleLoadWorld(url, worldInfo, offlineMode)
        if not url then
            return false
        end
        
        if overtimeEnter and Mod.WorldShare.Store:Get('world/isEnterWorld') then
            return false
        end

        local function LoadWorld(world, refreshMode)
            if world then
                if refreshMode == 'never' then
                    if not LocalService:IsFileExistInZip(world:GetLocalFileName(), ":worldconfig.txt") then
                        refreshMode = 'force'
                    end
                end

                local url = world:GetLocalFileName()
                DownloadWorld.ShowPage(url)
                local mytimer = commonlib.Timer:new(
                    {
                        callbackFunc = function(timer)
                            InternetLoadWorld.LoadWorld(
                                world,
                                nil,
                                refreshMode or "auto",
                                function(bSucceed, localWorldPath)
                                    DownloadWorld.Close()
                                end
                            )
                        end
                    }
                );

                -- prevent recursive calls.
                mytimer:Change(1,nil);
            else
                _guihelper.MessageBox(L"无效的世界文件");
            end
        end

        if url:match("^https?://") then
            world = RemoteWorld.LoadFromHref(url, "self")
            world:SetProjectId(pid)
            local token = Mod.WorldShare.Store:Get("user/token")
            if token then
                world:SetHttpHeaders({Authorization = format("Bearer %s", token)})
            end

            local fileUrl = world:GetLocalFileName()

            Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

            if ParaIO.DoesFileExist(fileUrl) then
                if offlineMode then
                    LoadWorld(world, "never")
                    return false
                end

                Mod.WorldShare.MsgBox:Show(L"请稍候...")
                GitService:GetWorldRevision(pid, false, function(data, err)
                    local localRevision = tonumber(LocalService:GetZipRevision(fileUrl)) or 0
                    local remoteRevision = tonumber(data) or 0

                    Mod.WorldShare.MsgBox:Close()

                    if localRevision == 0 then
                        LoadWorld(world, "auto")

                        return false
                    end

                    if localRevision == remoteRevision then
                        LoadWorld(world, "never")

                        return false
                    end

					if refreshMode == "force" then
						LoadWorld(world, refreshMode);
						return false;
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
                        "Mod/WorldShare/cellar/Common/LoadWorld/ProjectIdEnter.html?project_id=" 
                            .. pid
                            .. "&remote_revision=" .. remoteRevision
                            .. "&local_revision=" .. localRevision
                            .. "&world_name=" .. worldName,
                        "ProjectIdEnter",
                        0,
                        0,
                        "_fi",
                        false
                    )

                    params._page.callback = function(data)
                        if data == 'local' then
                            LoadWorld(world, "never")
                        elseif data == 'remote' then
                            LoadWorld(world, "force")
                        end
                    end
                end)
            else
                LoadWorld(world, "auto")
            end
        end
	end

    -- show view over 10 seconds
    Mod.WorldShare.Utils.SetTimeOut(function()
        if fetchSuccess then
            return false
        end

        MainLogin:Close()
        Create:Show()
        Mod.WorldShare.MsgBox:Close()
    end, 10000)

    Mod.WorldShare.MsgBox:Show(L"请稍候...", 20000)

    KeepworkServiceProject:GetProject(
        pid,
        function(data, err)
            Mod.WorldShare.MsgBox:Close()
            fetchSuccess = true

            if err == 0 then
                local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

                if not cacheWorldInfo or not cacheWorldInfo.worldInfo then
                    GameLogic.AddBBS(nil, L"网络环境差，或离线中，请联网后再试", 3000, "255 0 0")
                    return false
                end

                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                HandleLoadWorld(cacheWorldInfo.worldInfo.archiveUrl, cacheWorldInfo.worldInfo, true)

                return false
            end

            if err == 404 then
                GameLogic.AddBBS(nil, L"未找到对应内容", 3000, "255 0 0")

                if failed then
                    _guihelper.MessageBox(
                        L'未能成功进入该地图，将帮您传送到【创意空间】。 ',
                        function()
                            local mainWorldProjectId = LocalServiceWorld:GetMainWorldProjectId()
                            self:EnterWorldById(mainWorldProjectId, true)
                        end,
                        _guihelper.MessageBoxButtons.OK_CustomLabel
                    )
                end
                return false
            end

            if err ~= 200 then
                GameLogic.AddBBS(nil, L"服务器维护中...", 3000, "255 0 0")
                return
            end

            if data and data.visibility == 1 then
                if not KeepworkServiceSession:IsSignedIn() then
                    LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                        if bIsSuccessed then
                            self:EnterWorldById(pid, refreshMode)
                        end
                    end)
                    return false
                else
                    KeepworkServiceProject:GetMembers(pid, function(members, err)
                        if type(members) ~= 'table' then
                            return false
                        end

                        local username = Mod.WorldShare.Store:Get("user/username")
                        
                        for key, item in ipairs(members) do
                            if item and item.username and item.username == username then
                                if not data.world or not data.world.archiveUrl then
                                    return false
                                end

                                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                                HandleLoadWorld(data.world.archiveUrl .. "&private=true", data.world)
                                return true
                            end
                        end

                        GameLogic.AddBBS(nil, L"您未获得该项目的访问权限", 3000, "255 0 0")
                        return false
                    end)
                end
            else
                -- vip enter
                if not self.vipVerified and
                   data and
                   data.extra and
                   ((data.extra.vipEnabled and data.extra.vipEnabled == 1) or
                   (data.extra.isVipWorld and data.extra.isVipWorld == 1)) then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                            if bIsSuccessed then
                                self:EnterWorldById(pid, refreshMode)
                            end
                        end)
                    else
                        local username = Mod.WorldShare.Store:Get("user/username")
    
                        if data.username and data.username ~= username then
                            GameLogic.IsVip('Vip', true, function(result)
                                if result then
                                    self.vipVerified = true
                                    self:EnterWorldById(pid, refreshMode)
                                end
                            end, 'Vip')
                        end
                    end

                    return
                end

                self.vipVerified = false

                -- vip institute enter
                if data and
                   data.extra and
                   data.extra.instituteVipEnabled and
                   data.extra.instituteVipEnabled == 1 and
                   not self.instituteVerified then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                            if bIsSuccessed then
                                self:EnterWorldById(pid, refreshMode)
                            end
                        end)
                        return
                    else
                        GameLogic.IsVip('IsOrgan', true, function(result)
                            if result then
                                self.instituteVerified = true
                                self:EnterWorldById(pid, refreshMode)
                            else
                                _guihelper.MessageBox(L"你没有权限进入此世界（机构VIP）")
                            end
                        end, 'Institute')
                    end
                    return
                end

                self.instituteVerified = false


                local enter_cb = function()
                    if data.world and data.world.archiveUrl and #data.world.archiveUrl > 0 then
                        Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                        HandleLoadWorld(data.world.archiveUrl, data.world)
                        CacheProjectId:SetProjectIdInfo(pid, data.world)
                    else
                        GameLogic.AddBBS(nil, L"未找到对应内容", 3000, "255 0 0")
                        
                        if failed then
                            _guihelper.MessageBox(
                                L'未能成功进入该地图，将帮您传送到【创意空间】。 ',
                                function()
                                    local mainWorldProjectId = LocalServiceWorld:GetMainWorldProjectId()
                                    self:EnterWorldById(mainWorldProjectId, true)
                                end,
                                _guihelper.MessageBoxButtons.OK_CustomLabel
                            )
                        end
                    end
                end

                if data and data.extra and data.extra.encode_world == 1 then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                            if bIsSuccessed then
                                self:EnterWorldById(pid, refreshMode)
                            end
                        end)
                        return false
                    else
                        local username = Mod.WorldShare.Store:Get("user/username")

                        if data.username and data.username == username then
                            enter_cb()
                        else
                            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyDecodePage.lua").Show(data, enter_cb);
                        end
                    end

                else
                    enter_cb()
                end
            end
        end
    )
end