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

-- bottles
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local HistoryManager = NPL.load("(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua")
local BrowseRemoteWorlds = NPL.load("(gl)Mod/WorldShare/cellar/BrowseRemoteWorlds/BrowseRemoteWorlds.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')

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

function UserConsole:HandleWorldId(...)
    CommonLoadWorld:EnterWorldById(...)
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
