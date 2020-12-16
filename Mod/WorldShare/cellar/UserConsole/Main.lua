--[[
Title: UserConsole Page
Author(s):  big, minor refactor by LiXizhi
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
------------------------------------------------------------
]]

-- libs
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local GameMainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin")
local ExplorerApp = commonlib.gettable("Mod.ExplorerApp")

-- UI
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local HistoryManager = NPL.load("(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua")
local BrowseRemoteWorlds = NPL.load("(gl)Mod/WorldShare/cellar/BrowseRemoteWorlds/BrowseRemoteWorlds.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local LocalServiceWorld = NPL.load("(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")

-- databse
local CacheProjectId = NPL.load("(gl)Mod/WorldShare/database/CacheProjectId.lua")

local UserConsole = NPL.export()

function UserConsole:ShowKickOutPage(reason)
    if self.isKickOutPageOpened then
        return false
    end

    self.isKickOutPageOpened = true
    UserInfo:Logout('KICKOUT')
    Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/UserConsole/KickOut.html?reason=" .. reason or 1, "LoginModal.KickOut", 0, 0, "_fi", false, 15)
end

-- this is called from ParaWorld Login App
function UserConsole:CheckShowUserWorlds()
    if System.options.showUserWorldsOnce then
        UserConsole.OnClickOfficialWorlds(function()
            System.options.showUserWorldsOnce = nil
            self:ClosePage()
        end)
        return true
    end
end

function UserConsole:ShowPage()
    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    if UserConsolePage then
        WorldList:RefreshCurrentServerList()
        return true
    end

    if self:CheckShowUserWorlds() then
        return false
    end

    local params = Mod.WorldShare.Utils.ShowWindow(850, 490, "(ws)UserConsole", "Mod.WorldShare.UserConsole")

    -- load last selected avatar if world is not loaded before.
    UserInfo:OnChangeAvatar()

    Mod.WorldShare.Store:Subscribe("user/Logout", function()
        WorldList:RefreshCurrentServerList()
    end)

    Mod.WorldShare.Store:Subscribe("user/Login", function()
        WorldList:RefreshCurrentServerList()
    end)

    if not self.notFirstTimeShown then
        self.notFirstTimeShown = true

        -- for restart
        if not KeepworkService:IsSignedIn() and KeepworkServiceSession:GetCurrentUserToken() then
            UserInfo:LoginWithToken()
            return false
        end

        -- for protocol
        if not KeepworkService:IsSignedIn() and KeepworkServiceSession:GetUserTokenFromUrlProtocol() then
            UserInfo:LoginWithToken()
            return false
        end

        -- auto sign in here
        if not KeepworkService:IsSignedIn() then
            UserInfo:CheckDoAutoSignin()
        end
    end

    WorldList:RefreshCurrentServerList()
end

function UserConsole:EnterMainLogin()
    if System.options.mc == true then
        GameMainLogin:next_step({IsLoginModeSelected = false})
    end
end

function UserConsole:ClosePage()
    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    if UserConsolePage then
        if Mod.WorldShare.Store:Get('world/isEnterWorld') then
            -- selecting the world in the world list will change current world data, we should load current world data again when user console page close.
            Compare:GetCurrentWorldInfo()
        end

        UserConsolePage:CloseWindow()
        Mod.WorldShare.Store:Unsubscribe("user/Login")
        Mod.WorldShare.Store:Unsubscribe("user/Logout")
        Mod.WorldShare.Store:Remove('page/Mod.WorldShare.UserConsole')
    end
end

function UserConsole:Refresh(time)
    UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    if UserConsolePage then
        UserConsolePage:Refresh(time or 0.01)
    end
end

function UserConsole:IsShowUserConsole()
    if Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole') then
        return true
    else
        return false
    end
end

function UserConsole.InputSearchContent()
    InternetLoadWorld.isSearching = true

    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    if UserConsolePage then
        UserConsolePage:Refresh(0.1)
    end
end

function UserConsole.IsMCVersion()
    if System.options.mc then
        return true;
    else
        return false;
    end
end

function UserConsole.OnImportWorld()
    Map3DSystem.App.Commands.Call("File.WinExplorer", Mod.WorldShare.Utils.GetWorldFolderFullPath())
end

function UserConsole.OnClickOfficialWorlds(callback)
    if ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL) then
        BrowseRemoteWorlds.ShowPage(callback)
        return true
    end

    Mod.WorldShare.Store:Set("world/personalMode", true)

    if ExplorerApp then
        ExplorerApp:Init(callback)
    end
end

function UserConsole:CreateNewWorld()
    self:ClosePage()
    CreateWorld:CreateNewWorld()
end

function UserConsole:ShowHistoryManager()
    HistoryManager:ShowPage()
end

function UserConsole:GetProjectId(url)
    if (tonumber(url or '') or 99999) < 99999 then
        return url
    end

    local pid = string.match(url or '', "^p(%d+)$")

    if not pid then
        pid = string.match(url or '', "/pbl/project/(%d+)")
    end

    return pid or false
end

function UserConsole:HandleWorldId(pid, refreshMode, failed)
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

            -- set remote world value here bacause local path
            Mod.WorldShare.Store:Set('world/currentRemoteWorld', world)

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
                        "Mod/WorldShare/cellar/UserConsole/ProjectIdEnter.html?project_id=" 
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

    -- show view over 5 seconds
    Mod.WorldShare.Utils.SetTimeOut(function()
        if fetchSuccess then
            return false
        end

        Mod.WorldShare.Store:Set('world/openKpProjectId', pid)

        local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

        if not cacheWorldInfo or not cacheWorldInfo.worldInfo or not cacheWorldInfo.worldInfo.archiveUrl then
            return false
        end

        local worldInfo = cacheWorldInfo.worldInfo
        local url = cacheWorldInfo.worldInfo.archiveUrl
        local world = RemoteWorld.LoadFromHref(url, "self")
        world:SetProjectId(pid)
        local fileUrl = world:GetLocalFileName()   
        local localRevision = tonumber(LocalService:GetZipRevision(fileUrl)) or 0
        
        -- set remote world value here bacause local path
        Mod.WorldShare.Store:Set('world/currentRemoteWorld', world)

        local worldName = ''

        if worldInfo and worldInfo.extra and worldInfo.extra.worldTagName then
            worldName = worldInfo.extra.worldTagName
        else
            worldName = worldInfo.worldName
        end

        local function LoadWorld(world, refreshMode)
            if world then
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
                                    return true
                                end
                            )
                        end
                    }
                );

                -- prevent recursive calls.
                mytimer:Change(1,nil);
            else
                _guihelper.MessageBox(L"无效的世界文件")
            end
        end

        local params = Mod.WorldShare.Utils.ShowWindow(
            0,
            0,
            "Mod/WorldShare/cellar/UserConsole/ProjectIdEnter.html?project_id=" 
                .. pid
                .. "&remote_revision=" .. 0
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
                overtimeEnter = true
                LoadWorld(world, "never")
            end
        end
    end, 5000)

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
                            self:HandleWorldId(mainWorldProjectId, true)
                        end,
                        _guihelper.MessageBoxButtons.OK
                    )
                end
                return false
            end

            if err ~= 200 then
                GameLogic.AddBBS(nil, L"服务器维护中...", 3000, "255 0 0")
                return
            end

            if data and data.visibility == 1 then
                if not KeepworkService:IsSignedIn() then
                    LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                        if bIsSuccessed then
                            self:HandleWorldId(pid, refreshMode)
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
                if data and data.extra and data.extra.vipEnabled == 1 or data.extra.institudeEnabled == 1 then
                    if not KeepworkService:IsSignedIn() then
                        LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                            if bIsSuccessed then
                                self:HandleWorldId(pid, refreshMode)
                            end
                        end)
                        return false
                    end
    
                    local userType = Mod.WorldShare.Store:Get("user/userType")
                    local username = Mod.WorldShare.Store:Get("user/username")
                    local isVip = Mod.WorldShare.Store:Get("user/isVip")

                    local canEnter = false

                    if data.username and data.username == username then
                        canEnter = true
                    end

                    if data.extra.vipEnabled == 1 then
                        if isVip then
                            canEnter = true
                        end
                    end

                    if data.extra.institudeEnabled == 1 then
                        if userType.student then
                            canEnter = true
                        end
                    end

                    if not canEnter then
                        _guihelper.MessageBox(L"你没有权限进入此世界")
                        return false
                    end
                end

                if data.world and data.world.archiveUrl and #data.world.archiveUrl > 0 then
                    Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                    HandleLoadWorld(data.world.archiveUrl, data.world)
                    CacheProjectId:SetProjectIdInfo(pid, data.world)
                else
                    GameLogic.AddBBS(nil, L"未找到对应内容", 3000, "255 0 0")
                end
            end
        end
    )
end

function UserConsole:WorldRename(currentItemIndex, tempModifyWorldname, callback)
    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    if not UserConsolePage then
        return false
    end

    local currentWorld = WorldList:GetSelectWorld(currentItemIndex)

    if not currentWorld then
        return false
    end

    if currentWorld.is_zip then
        GameLogic.AddBBS(nil, L"暂不支持重命名zip世界", 3000, "255 0 0")
        return false
    end

    if tempModifyWorldname == "" then
        return false
    end

    local tag

    if currentWorld.status ~= 2 then
        if currentWorld.local_tagname == tempModifyWorldname then
            return false
        end

        local saveWorldHandler = SaveWorldHandler:new():Init(currentWorld.worldpath)
        tag = saveWorldHandler:LoadWorldInfo()

        -- update local tag name
        tag.name = tempModifyWorldname
        currentWorld.local_tagname = tempModifyWorldname

        saveWorldHandler:SaveWorldInfo(tag)
        Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    end

    if KeepworkService:IsSignedIn() and currentWorld.status ~= 1 and currentWorld.kpProjectId then
        -- update project info

        if tag then
            -- update sync world
            -- local world exist
            Mod.WorldShare.Store:Set('world/currentRevision', currentWorld.revision)

            SyncMain:SyncToDataSource(function(result, msg)
                if type(callback) == 'function' then
                    callback()
                end
            end)
        else
            -- just remote world exist
            KeepworkServiceWorld:GetWorld(currentWorld.foldername, currentWorld.shared, function(data)
                local extra = data and data.extra or {}

                extra.worldTagName = tempModifyWorldname

                -- local world not exist
                KeepworkServiceProject:UpdateProject(
                    currentWorld.kpProjectId,
                    {
                        extra = extra
                    },
                    function()
                        -- update world info
                        KeepworkServiceWorld:PushWorld(
                            {
                                worldName = currentWorld.foldername,
                                extra = extra
                            },
                            currentWorld.shared,
                            function()
                                if type(callback) == 'function' then
                                    callback()
                                end
                            end
                        )
                    end
                )
            end)
        end
    else
        if type(callback) == 'function' then
            callback()
        end
    end

    return true
end
