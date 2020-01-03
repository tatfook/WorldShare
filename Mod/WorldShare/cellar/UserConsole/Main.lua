--[[
Title: login
Author(s):  big, minor refactor by LiXizhi
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
------------------------------------------------------------
]]
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")

local WorldShare = commonlib.gettable("Mod.WorldShare")
local ExplorerApp = commonlib.gettable("Mod.ExplorerApp")
local Encoding = commonlib.gettable("commonlib.Encoding")

local UserInfo = NPL.load("./UserInfo.lua")
local WorldList = NPL.load("./WorldList.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local HistoryManager = NPL.load("(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua")
local BrowseRemoteWorlds = NPL.load("(gl)Mod/WorldShare/cellar/BrowseRemoteWorlds/BrowseRemoteWorlds.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local CacheProjectId = NPL.load("(gl)Mod/WorldShare/database/CacheProjectId.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")

local UserConsole = NPL.export()

function UserConsole.IsSignedIn()
   return KeepworkService:IsSignedIn()
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
    if self:CheckShowUserWorlds() then
        return false
    end

    local params = Mod.WorldShare.Utils.ShowWindow(850, 470, "Mod/WorldShare/cellar/UserConsole/UserConsole.html", "UserConsole")

    -- load last selected avatar if world is not loaded before.
    UserInfo:OnChangeAvatar()

    local notFirstTimeShown = Mod.WorldShare.Store:Get('user/notFirstTimeShown')

    if notFirstTimeShown then
        Mod.WorldShare.Store:Set('user/ignoreAutoLogin', true)
    else
        Mod.WorldShare.Store:Set('user/notFirstTimeShown', true)

        KeepworkServiceSession:GetUserTokenFromUrlProtocol()

        -- for restart game
        if KeepworkServiceSession:GetCurrentUserToken() then
            UserInfo:LoginWithToken()
            return false
        end

        local ignoreAutoLogin = Mod.WorldShare.Store:Get('user/ignoreAutoLogin')

        if not ignoreAutoLogin then
            -- auto sign in here
            UserInfo:CheckDoAutoSignin()
        end
    end

    WorldList:RefreshCurrentServerList()
end

function UserConsole:ClosePage()
    if UserConsole.IsMCVersion() then
        InternetLoadWorld.ReturnLastStep()
    end

    local UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

    if UserConsolePage then
        if Mod.WorldShare.Store:Get('world/isEnterWorld') then
            -- selecting the world in the world list will change current world data, we should load current world data again when user console page close.
            Compare:GetCurrentWorldInfo()
        end

        UserConsolePage:CloseWindow()
    end
end

function UserConsole:Refresh(time)
    UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

    if UserConsolePage then
        UserConsolePage:Refresh(time or 0.01)
    end
end

function UserConsole:IsShowUserConsole()
    if Mod.WorldShare.Store:Get('page/UserConsole') then
        return true
    else
        return false
    end
end

function UserConsole.InputSearchContent()
    InternetLoadWorld.isSearching = true

    local UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

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

function UserConsole:HandleWorldId(pid)
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
                            );
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
            local fileUrl = world:GetLocalFileName()

            if ParaIO.DoesFileExist(fileUrl) then
                if offlineMode then
                    LoadWorld(world, "never")
                    return false
                end

                Mod.WorldShare.MsgBox:Show(L"请稍后...")
                GitService:GetWorldRevision(pid, false, function(data, err)
                    local localRevision = tonumber(LocalService:GetZipRevision(fileUrl)) or 0
                    local remoteRevision = tonumber(data) or 0

                    Mod.WorldShare.MsgBox:Close()

                    if localRevision == 0 then
                        LocalLoadWorld(world, "auto")

                        return false
                    end

                    if localRevision == remoteRevision then
                        LoadWorld(world, "never")

                        return false
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
                            LoadWorld(world, "auto")
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
        local fileUrl = world:GetLocalFileName()   
        local localRevision = tonumber(LocalService:GetZipRevision(fileUrl)) or 0

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

    Mod.WorldShare.MsgBox:Show(L"请稍后...", 20000)

    KeepworkService:GetWorldByProjectId(
        pid,
        function(worldInfo, err)
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
                return false
            end

            if worldInfo and worldInfo.archiveUrl and #worldInfo.archiveUrl > 0 then
                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                HandleLoadWorld(worldInfo.archiveUrl, worldInfo)
                CacheProjectId:SetProjectIdInfo(pid, worldInfo)
            else
                GameLogic.AddBBS(nil, L"未找到对应内容", 3000, "255 0 0")
            end
        end
    )
    
end

function UserConsole:WorldRename(currentItemIndex, tempModifyWorldname, callback)
    local UserConsolePage = Mod.WorldShare.Store:Get('page/UserConsole')

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

        saveWorldHandler:SaveWorldInfo(tag)

        currentWorld.local_tagname = tempModifyWorldname

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
            KeepworkServiceWorld:GetWorld(currentWorld.foldername, function(data)
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