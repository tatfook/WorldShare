--[[
Title: WorldShareMod
Author(s):  Big
Date: 2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/main.lua")
local WorldShare = commonlib.gettable("Mod.WorldShare")
------------------------------------------------------------

CODE GUIDELINE

1. all classes and functions use upper camel case
2. all variables use lower camel case
3. all files use use upper camel case
4. all templates variables and functions use underscore case

]]

-- include ide
NPL.load("(gl)script/ide/Files.lua")
NPL.load("(gl)script/ide/Encoding.lua")

-- include ide system encoding
NPL.load("(gl)script/ide/System/Encoding/sha1.lua")
NPL.load("(gl)script/ide/System/Encoding/base64.lua")
NPL.load("(gl)script/ide/System/Encoding/guid.lua")
NPL.load("(gl)script/ide/System/Encoding/jwt.lua")
NPL.load("(gl)script/ide/System/Encoding/basexx.lua")

-- include ide system windows
NPL.load("(gl)script/ide/System/Windows/Screen.lua")

-- include ide system scene
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua")

-- include ide system core
NPL.load("(gl)script/ide/System/Core/UniString.lua")
NPL.load("(gl)script/ide/System/Core/Event.lua")
NPL.load("(gl)script/ide/System/Core/ToolBase.lua")

-- include ide system os
NPL.load("(gl)script/ide/System/os/os.lua")

-- include aries creator
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua")

-- include aries creator game login
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherAgent.lua")

-- include aries creator game areas
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua")

-- include aries creator game network
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua")

-- include aries creator game world
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua")

-- include aries creator game login
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLessons.lua")

-- include aries creator game nplbrowser
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua")

-- include worldshare service
NPL.load("(gl)Mod/WorldShare/service/SocketService.lua")
NPL.load("(gl)Mod/WorldShare/service/Cef3Manager.lua")


-- get table lib
local SocketService = commonlib.gettable("Mod.WorldShare.service.SocketService")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Cef3Manager = commonlib.gettable("Mod.WorldShare.service.Cef3Manager")

-- UI
local MainLogin = NPL.load("(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local UserConsoleCreate = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Create/Create.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
local HistoryManager = NPL.load("(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua")
local WorldExitDialog = NPL.load("(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua")
local PreventIndulge = NPL.load("(gl)Mod/WorldShare/cellar/PreventIndulge/PreventIndulge.lua")
local Grade = NPL.load("(gl)Mod/WorldShare/cellar/Grade/Grade.lua")
local VipNotice = NPL.load("(gl)Mod/WorldShare/cellar/VipNotice/VipNotice.lua")
local Permission = NPL.load("(gl)Mod/WorldShare/cellar/Permission/Permission.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local Menu = NPL.load("(gl)Mod/WorldShare/cellar/Menu/Menu.lua")

-- service
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local EventTrackingService = NPL.load("(gl)Mod/WorldShare/service/EventTracking.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")

-- helper
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox/MsgBox.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

-- command
local WorldShareCommand = NPL.load("(gl)Mod/WorldShare/command/Command.lua")
local MenuCommand = NPL.load("(gl)Mod/WorldShare/command/Menu.lua")

local WorldShare = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("Mod.WorldShare"))

WorldShare:Property({"Name", "WorldShare", "GetName", "SetName", { auto = true }})
WorldShare:Property({"Desc", "world share mod can share world to keepwork online", "GetDesc", "SetDesc", { auto = true }})
WorldShare.version = '0.0.20'

if Config.defaultEnv == 'RELEASE' or Config.defaultEnv == 'STAGE' then
    System.options.isAB_SDK = true
end

-- register mod global variable
WorldShare.Store = Store
WorldShare.MsgBox = MsgBox
WorldShare.Utils = Utils

LOG.std(nil, "info", "WorldShare", "world share version %s", WorldShare.version)

function WorldShare:init()
    -- replace load world page
    GameLogic.GetFilters():add_filter(
        "ShowLoginModePage",
        function()
            MainLogin:Show()
            return false
        end
    )

    GameLogic.GetFilters():add_filter(
        "ShowClientUpdaterNotice",
        function()
            if Mod.WorldShare.Utils.IsEnglish() then
                Mod.WorldShare.MsgBox:Show(L"checking for updates...", nil, nil, nil, nil, nil, "_ct")
            else
                Mod.WorldShare.MsgBox:Show(L"正在检查更新， 请稍候...", nil, nil, nil, nil, nil, "_ct")
            end
        end
    )

    GameLogic.GetFilters():add_filter(
        "HideClientUpdaterNotice",
        function()
            Mod.WorldShare.MsgBox:Close()
        end
    )

    -- replace load world page
    GameLogic.GetFilters():add_filter(
        "InternetLoadWorld.ShowPage",
        function(bEnable, bShow)
            local worldsharebeat = ParaEngine.GetAppCommandLineByParam("worldsharebeat", nil)

            if worldsharebeat and worldsharebeat == 'true' then
                UserConsoleCreate:Show()
            else
                UserConsole:ShowPage()
            end
            -- UserConsoleCreate:Show()
            return false
        end
    )

    -- replace the exit world dialog
    GameLogic.GetFilters():add_filter(
        "ShowExitDialog",
        function(dialog)
            if (dialog and dialog.callback) then
                WorldExitDialog.ShowPage(dialog.callback)
                return nil
            end
        end
    )

    -- replace share world page
    GameLogic.GetFilters():add_filter(
        "SaveWorldPage.ShowSharePage",
        function(bEnable, callback)
            ShareWorld:Init(bEnable, callback)
            return false
        end
    )

    -- replace implement or replace create new world event
    GameLogic.GetFilters():add_filter(
        "OnClickCreateWorld",
        function()
            return CreateWorld.OnClickCreateWorld()
        end
    )

    -- replcae implement local world event
    GameLogic.GetFilters():add_filter(
        "load_world_info",
        function(ctx, node)
            LocalService:LoadWorldInfo(ctx, node)
        end
    )

    -- replace implement save world event
    GameLogic.GetFilters():add_filter(
        "save_world_info",
        function(ctx, node)
            LocalService:SaveWorldInfo(ctx, node)
        end
    )

    -- vip notice
    GameLogic.GetFilters():add_filter(
        "VipNotice",
        function(bEnabled, callback)
            VipNotice:Init(bEnabled, callback)
            return true
        end
    )

    -- filter KeepworkPremission
    GameLogic.GetFilters():add_filter(
        "KeepworkPermission",
        function(bEnabled, authName, bOpenUIIfNot, callback)
            Permission:CheckPermission(authName, bOpenUIIfNot, callback)

            return true
        end
    )

    -- filter CheckSignedIn
    GameLogic:GetFilters():add_filter(
        "LoginModal.CheckSignedIn",
        function(bEnabled, desc, callback)
            LoginModal:CheckSignedIn(desc, callback)
            return true
        end
    )
    
    -- filter menu project
    GameLogic:GetFilters():add_filter(
        "desktop_menu",
        function(menuItems)
            return Menu:Init(menuItems)
        end
    )

    -- filter menu command
    GameLogic:GetFilters():add_filter(
        "menu_command",
        function(bEnable, cmdName, cmdText, cmdParams)
            return MenuCommand:Call(cmdName, cmdText, cmdParams)
        end
    )

    -- filter user behavior
    GameLogic:GetFilters():add_filter(
        "user_behavior",
        function(type, action)
            EventTrackingService:Send(type, action)
        end
    )

    -- send udp online msg
    SocketService:StartUDPService()

    -- refresh token
    KeepworkServiceSession:RenewToken()

    -- prevent indulage
    PreventIndulge:Init()

    -- event tracking init
    EventTrackingService:Init()

    -- init cef3 for windows
    if System.os.GetPlatform() == "win32" then
        Cef3Manager:Init()
    end

    -- init long tcp connection
    KeepworkServiceSession:LongConnectionInit(function(result)
        if type(result) ~= 'table' then
            return false
        end

        if result.action == 'kickOut' then
            local reason = 1

            if result.payload and result.payload.reason then
                reason = result.payload.reason
            end

            Mod.WorldShare.Store:Action("user/Logout")()
            UserConsole:ShowKickOutPage(reason)
        end
    end)

    WorldShareCommand:Init()
end

function WorldShare:OnInitDesktop()
end

function WorldShare:OnLogin()
end

function WorldShare:OnWorldLoad()
    Store:Set('world/isEnterWorld', true)

    UserConsole:ClosePage()
    HistoryManager:OnWorldLoad()

    local curLesson = Store:Getter("lesson/GetCurLesson")

    -- if enter with lesson method, we will not check revision
    if not curLesson then
        SyncMain:OnWorldLoad()
    end

    Store:Subscribe("user/Logout", function()
        Compare:RefreshWorldList(function()
            Compare:GetCurrentWorldInfo()
        end)
    end)

    Store:Subscribe("user/Login", function()
        Compare:RefreshWorldList(function()
            Compare:GetCurrentWorldInfo()
        end)
    end)
end

function WorldShare:OnLeaveWorld()
    Store:Remove("world/currentWorld")
end