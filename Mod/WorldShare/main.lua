--[[
Title: WorldShareMod
Author(s):  Big
Date: 2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load('(gl)Mod/WorldShare/main.lua')
local WorldShare = commonlib.gettable('Mod.WorldShare')
------------------------------------------------------------

CODE GUIDELINE

1. all classes and functions use upper camel case.
2. all variables use lower camel case.
3. all files use use upper camel case.
4. all templates variables and functions use underscore case.
5. single quotation marks are used for strings.

]]

-- include ide
NPL.load('(gl)script/ide/Files.lua')
NPL.load('(gl)script/ide/Encoding.lua')

-- include ide system encoding
NPL.load('(gl)script/ide/System/Encoding/sha1.lua')
NPL.load('(gl)script/ide/System/Encoding/base64.lua')
NPL.load('(gl)script/ide/System/Encoding/guid.lua')
NPL.load('(gl)script/ide/System/Encoding/jwt.lua')
NPL.load('(gl)script/ide/System/Encoding/basexx.lua')

-- include ide system windows
NPL.load('(gl)script/ide/System/Windows/Screen.lua')

-- include ide system scene
NPL.load('(gl)script/ide/System/Scene/Viewports/ViewportManager.lua')

-- include ide system core
NPL.load('(gl)script/ide/System/Core/UniString.lua')
NPL.load('(gl)script/ide/System/Core/Event.lua')
NPL.load('(gl)script/ide/System/Core/ToolBase.lua')

-- include ide system os
NPL.load('(gl)script/ide/System/os/os.lua')

-- include aries creator
NPL.load('(gl)script/apps/Aries/Creator/WorldCommon.lua')

-- include aries creator game login
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherAgent.lua')
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherIcon.lua")
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLessons.lua')

-- include aries creator game areas
NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua')

-- include aries creator game network
NPL.load('(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua')

-- include aries creator game world
NPL.load('(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua')

-- include aries creator game tasks
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");

-- include aries creator game nplbrowser
NPL.load('(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua')

-- include worldshare service
NPL.load('(gl)Mod/WorldShare/service/SocketService.lua')
NPL.load('(gl)Mod/WorldShare/service/Cef3Manager.lua')


-- get table lib
local SocketService = commonlib.gettable('Mod.WorldShare.service.SocketService')
local GameLogic = commonlib.gettable('MyCompany.Aries.Game.GameLogic')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local Cef3Manager = commonlib.gettable('Mod.WorldShare.service.Cef3Manager')

-- UI
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local UserConsole = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/Main.lua')
local UserConsoleCreate = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/Create/Create.lua')
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
local SyncMain = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Main.lua')
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')
local HistoryManager = NPL.load('(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua')
local WorldExitDialog = NPL.load('(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
local PreventIndulge = NPL.load('(gl)Mod/WorldShare/cellar/PreventIndulge/PreventIndulge.lua')
local Grade = NPL.load('(gl)Mod/WorldShare/cellar/Grade/Grade.lua')
local VipNotice = NPL.load('(gl)Mod/WorldShare/cellar/VipNotice/VipNotice.lua')
local Permission = NPL.load('(gl)Mod/WorldShare/cellar/Permission/Permission.lua')
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local Menu = NPL.load('(gl)Mod/WorldShare/cellar/Menu/Menu.lua')
local Beginner = NPL.load('(gl)Mod/WorldShare/cellar/Beginner/Beginner.lua')
local Certificate = NPL.load("(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')

-- helper
local Store = NPL.load('(gl)Mod/WorldShare/store/Store.lua')
local MsgBox = NPL.load('(gl)Mod/WorldShare/cellar/Common/MsgBox/MsgBox.lua')
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')

-- command
local WorldShareCommand = NPL.load('(gl)Mod/WorldShare/command/Command.lua')
local MenuCommand = NPL.load('(gl)Mod/WorldShare/command/Menu.lua')

-- filters
local Filters = NPL.load('(gl)Mod/WorldShare/filters/Filters.lua')

local WorldShare = commonlib.inherit(commonlib.gettable('Mod.ModBase'), commonlib.gettable('Mod.WorldShare'))

WorldShare:Property({'Name', 'WorldShare', 'GetName', 'SetName', { auto = true }})
WorldShare:Property({'Desc', 'world share mod can share world to keepwork online', 'GetDesc', 'SetDesc', { auto = true }})
WorldShare.version = '0.0.21'

if Config.defaultEnv == 'RELEASE' or Config.defaultEnv == 'STAGE' then
    System.options.isAB_SDK = true
end

-- register mod global variable
WorldShare.Store = Store
WorldShare.MsgBox = MsgBox
WorldShare.Utils = Utils

LOG.std(nil, 'info', 'WorldShare', 'world share version %s', WorldShare.version)

function WorldShare:init()
    -- init all filters
    Filters:Init()

    -- replace load world page
    GameLogic.GetFilters():add_filter(
        'ShowLoginModePage',
        function()
            MainLogin:Show()
            return false
        end
    )

    GameLogic.GetFilters():add_filter(
        'ShowClientUpdaterNotice',
        function()
            if Mod.WorldShare.Utils.IsEnglish() then
                Mod.WorldShare.MsgBox:Show(L'checking for updates...', nil, nil, nil, nil, nil, '_ct')
            else
                Mod.WorldShare.MsgBox:Show(L'正在检查更新， 请稍候...', nil, nil, nil, nil, nil, '_ct')
            end
        end
    )

    GameLogic.GetFilters():add_filter(
        'HideClientUpdaterNotice',
        function()
            Mod.WorldShare.MsgBox:Close()
        end
    )

    -- replace load world page
    GameLogic.GetFilters():add_filter(
        'InternetLoadWorld.ShowPage',
        function(bEnable, bShow)
            local worldsharebeat = ParaEngine.GetAppCommandLineByParam('worldsharebeat', nil)

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
        'ShowExitDialog',
        function(dialog)
            if (dialog and dialog.callback) then
                WorldExitDialog.ShowPage(dialog.callback)
                return nil
            end
        end
    )

    -- replace share world page
    GameLogic.GetFilters():add_filter(
        'SaveWorldPage.ShowSharePage',
        function(bEnable, callback)
            ShareWorld:Init(bEnable, callback)
            return false
        end
    )

    -- replace implement or replace create new world event
    GameLogic.GetFilters():add_filter(
        'OnClickCreateWorld',
        function()
            return CreateWorld.OnClickCreateWorld()
        end
    )

    -- replcae implement local world event
    GameLogic.GetFilters():add_filter(
        'load_world_info',
        function(ctx, node)
            LocalService:LoadWorldInfo(ctx, node)
        end
    )

    -- replace implement save world event
    GameLogic.GetFilters():add_filter(
        'save_world_info',
        function(ctx, node)
            LocalService:SaveWorldInfo(ctx, node)
        end
    )

    -- vip notice
    GameLogic.GetFilters():add_filter(
        'VipNotice',
        function(bEnabled, from, callback)
            VipNotice:Init(bEnabled, from, callback)
            return true
        end
    )

    -- filter KeepworkPremission
    GameLogic.GetFilters():add_filter(
        'KeepworkPermission',
        function(bEnabled, authName, bOpenUIIfNot, callback)
            Permission:CheckPermission(authName, bOpenUIIfNot, callback)

            return true
        end
    )

    -- filter CheckSignedIn
    GameLogic:GetFilters():add_filter(
        'LoginModal.CheckSignedIn',
        function(bEnabled, desc, callback)
            LoginModal:CheckSignedIn(desc, callback)
            return true
        end
    )
    
    -- filter menu project
    GameLogic:GetFilters():add_filter(
        'desktop_menu',
        function(menuItems)
            return Menu:Init(menuItems)
        end
    )

    -- filter menu command
    GameLogic:GetFilters():add_filter(
        'menu_command',
        function(bEnable, cmdName, cmdText, cmdParams)
            return MenuCommand:Call(cmdName, cmdText, cmdParams)
        end
    )

    -- filter user behavior
    GameLogic:GetFilters():add_filter(
        'user_behavior',
        function(type, action, extra)
            EventTrackingService:Send(type, action, extra)
        end
    )

    -- filter old user behavior
    GameLogic:GetFilters():add_filter(
        'user_event_stat',
        function(category, action, value, label)            
            local sArray = {}

            for item in string.gmatch(action, "[^%:]+") do
                sArray[#sArray + 1] = item
            end

            local newActionName = "click.world." .. category .. "." .. sArray[1]

            EventTrackingService:Send(1, newActionName)

            -- count edit block
            if newActionName == 'click.world.block.create' or
               newActionName == 'click.world.block.destroy' then
                local blockCount = Store:Get('world/blockCount')

                if not blockCount or type(blockCount) ~= 'number' then
                    blockCount = 0
                end

                if newActionName == 'click.world.block.create' then
                    blockCount = blockCount + 1
                end

                if newActionName == 'click.world.block.destroy' then
                    blockCount = blockCount - 1
                end

                Store:Set('world/blockCount', blockCount)
            end

            return category
        end
    )

    -- filter show certificate page
    GameLogic.GetFilters():add_filter(
        'show_certificate_page',
        function(callback)
            Beginner:Show(callback)
            return false
        end
    )

    -- filter is signed in
    GameLogic.GetFilters():add_filter(
        'is_signed_in',
        function()
            return KeepworkServiceSession:IsSignedIn()
        end
    )

    -- filter set mode
    GameLogic.GetFilters():add_filter(
        'set_mode',
        function(mode, bFireModeChangeEvent)
            local loadWorldFinish = Mod.WorldShare.Store:Get('world/loadWorldFinish')

            if loadWorldFinish then
                if mode == 'editor' then
                    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.world.edit");

                    -- stop play event tracking
                    if GameLogic.GameMode:GetMode() ~= mode then
                        GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.play", { ended = true });
                    end
            
                    GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.edit", { started = true });
                else
                    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.world.play");

                    -- stop edit event tracking
                    if GameLogic.GameMode:GetMode() ~= mode then
                        GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.edit", { ended = true });
                    end
            
                    GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.play", { started = true });
                end
            end
        end
    )

    -- filter get user type
    GameLogic.GetFilters():add_filter(
        'get_user_type',
        function()
            return Mod.WorldShare.Store:Get("user/userType")
        end
    )

    -- filter get user id
    GameLogic.GetFilters():add_filter(
        'get_user_id',
        function()
            return Mod.WorldShare.Store:Get("user/userId") or 0
        end
    )

    -- filter get world by project id
    GameLogic.GetFilters():add_filter(
        'get_world_by_project_id',
        function(projectId, callback)
            KeepworkServiceWorld:GetWorldByProjectId(projectId, callback)
        end
    )

    -- filter get keepwork url
    GameLogic.GetFilters():add_filter(
        'get_keepwork_url',
        function()
            return KeepworkService:GetKeepworkUrl()
        end
    )

    -- filter get project id by lesson id
    GameLogic.GetFilters():add_filter(
        'get_project_id_by_lesson_id',
        function(txtLessonId)
            return UserConsole:GetProjectId(txtLessonId)
        end
    )

    -- filter on exit
    GameLogic.GetFilters():add_filter(
        'on_exit',
        function(bForceExit, bRestart, callback)
            EventTrackingService:SaveToDisk()

            if callback and type(callback) == 'function' then
                callback()
            end

            -- local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

            -- if (currentEnterWorld and currentEnterWorld.project and currentEnterWorld.project.memberCount or 0) > 1 then
            --     Mod.WorldShare.MsgBox:Show(L"请稍后...")
            --     local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")

            --     KeepworkServiceWorld:UnlockWorld(function()
            --         if callback and type(callback) == 'function' then
            --             callback()
            --         end
            --     end)
            -- else
            --     if callback and type(callback) == 'function' then
            --         callback()
            --     end
            -- end
        end
    )

    -- filter open keepwork url with token
    GameLogic.GetFilters():add_filter(
        'open_keepwork_url',
        function(url)
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
        end
    )

    -- filter check signed in
    GameLogic.GetFilters():add_filter(
        'check_signed_in',
        function(text, callback)
            local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
            LoginModal:CheckSignedIn(text, callback)
        end
    )

    -- filter show login page
    GameLogic.GetFilters():add_filter(
        'show_login_page',
        function()
            local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
            LoginModal:Init()
        end
    )

    -- filter qiniu upload file
    GameLogic.GetFilters():add_filter(
        'qiniu_upload_file',
        function(token, key, filename, content, callback)
            local QiniuRootApi = NPL.load("(gl)Mod/WorldShare/api/Qiniu/Root.lua")
            QiniuRootApi:Upload(token, key, filename, content, callback, callback)
        end
    )

    -- filter show create page
    GameLogic.GetFilters():add_filter(
        'show_create_page',
        function()
            UserConsoleCreate:Show()
		    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')
        end
    )

    -- filter show console page
    GameLogic.GetFilters():add_filter(
        'show_console_page',
        function()
            UserConsole:ShowPage()
		    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')
        end
    )

    -- filter compare init
    GameLogic.GetFilters():add_filter(
        'compare_init',
        function(callback)
            Compare:Init(callback)
        end
    )

    -- filter get current world
    GameLogic.GetFilters():add_filter(
        'current_world',
        function()
            return Mod.WorldShare.Store:Get('world/currentWorld')
        end
    )

    -- filter show offical worlds 
    GameLogic.GetFilters():add_filter(
        'show_offical_worlds_page',
        function()
            UserConsole.OnClickOfficialWorlds();
        end
    )

    -- filter check world updated before enter my home
    GameLogic.GetFilters():add_filter(
        'check_and_updated_before_enter_my_home',
        function(callback)
            SyncMain:CheckAndUpdatedBeforeEnterMyHome(function()
                GameLogic.RunCommand("/loadworld home");
            end)
        end
    )

    -- filter show server page
    GameLogic.GetFilters():add_filter(
        'show_server_page',
        function()
            local Server = NPL.load("(gl)Mod/WorldShare/cellar/Server/Server.lua")
            Server:ShowPage()
        end
    )

    -- filter get my orgs and school
    GameLogic.GetFilters():add_filter(
        'get_my_orgs_and_schools',
        function(callback)
            local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
            KeepworkServiceSchoolAndOrg:GetMyAllOrgsAndSchools(callback)
        end
    )

    -- filter get school region
    GameLogic.GetFilters():add_filter(
        'get_school_region',
        function(selectType, parentId, callback)
            local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
            KeepworkServiceSchoolAndOrg:GetSchoolRegion(selectType, parentId, callback)
        end
    )

    -- filter store set data
    GameLogic.GetFilters():add_filter(
        'store_set',
        function(key, value)
            Mod.WorldShare.Store:Set(key, value)
        end
    )

    -- filter store get data
    GameLogic.GetFilters():add_filter(
        'store_get',
        function(key)
            return Mod.WorldShare.Store:Get(key)
        end
    )

    -- filter login width token
    GameLogic.GetFilters():add_filter(
        'login_with_token',
        function(callback)
            local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
            UserInfo:LoginWithToken(callback)
        end
    )

    -- filter logout
    GameLogic.GetFilters():add_filter(
        'logout',
        function(mode, callback)
            KeepworkServiceSession:Logout(mode, callback);
        end
    )

    -- filter get single file
    GameLogic.GetFilters():add_filter(
        'get_single_file',
        function(pid, filename, callback, cdnState)
            local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
            KeepworkServiceWorld:GetSingleFile(pid, filename, callback, cdnState)
        end
    )

    -- filter get single file by commit id
    GameLogic.GetFilters():add_filter(
        'get_single_file_by_commit_id',
        function(pid, commitId, filename, callback, cdnState)
            local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
            KeepworkServiceWorld:GetSingleFileByCommitId(pid, commitId, filename, callback, cdnState)
        end
    )

    -- filter get socket url
    GameLogic.GetFilters():add_filter(
        'get_socket_url',
        function()
            local SocketBaseApi = NPL.load("(gl)Mod/WorldShare/api/Socket/BaseApi.lua")
            return SocketBaseApi:GetApi()
        end
    )

    -- filter get api url
    GameLogic.GetFilters():add_filter(
        'get_core_api_url',
        function()
            local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
            return KeepworkService:GetCoreApi()
        end
    )

    -- filter show certificate icon
    GameLogic.GetFilters():add_filter(
        'show_certificate',
        function(callback)
            Certificate:Init(callback)
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
    if System.os.GetPlatform() == 'win32' then
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

            Mod.WorldShare.Store:Action('user/Logout')()
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
    Store:Set('world/loadWorldFinish', true)

    UserConsole:ClosePage()

    local curLesson = Store:Getter('lesson/GetCurLesson')

    -- if enter with lesson method, we will not check revision
    if not curLesson then
        SyncMain:OnWorldLoad()
    end

    HistoryManager:OnWorldLoad()
    -- Certificate:OnWorldLoad()

    Store:Subscribe('user/Logout', function()
        Compare:RefreshWorldList(function()
            Compare:GetCurrentWorldInfo()
        end)
    end)

    Store:Subscribe('user/Login', function()
        Compare:RefreshWorldList(function()
            Compare:GetCurrentWorldInfo()
        end)
    end)

    EventTrackingService:Send(2, 'duration.world.stay', { started = true })

    if GameLogic.GameMode:GetMode() == 'editor' then
        EventTrackingService:Send(1, 'click.world.edit')
        EventTrackingService:Send(2, 'duration.world.edit', { started = true })
    else
        EventTrackingService:Send(1, 'click.world.play')
        EventTrackingService:Send(2, 'duration.world.play', { started = true })
    end

    Mod.WorldShare.Store:Remove("world/currentRemoteWorld")
end

function WorldShare:OnLeaveWorld()
    Store:Set('world/loadWorldFinish', false)

    local isEnterWorld = Mod.WorldShare.Store:Get('world/isEnterWorld')

    if isEnterWorld then
        EventTrackingService:Send(2, 'duration.world.stay', { ended = true })

        if GameLogic.GameMode:GetMode() == 'editor' then
            EventTrackingService:Send(2, 'duration.world.edit', { ended = true })
        else
            EventTrackingService:Send(2, 'duration.world.play', { ended = true })
        end
    end

    Store:Remove('world/currentWorld')
end