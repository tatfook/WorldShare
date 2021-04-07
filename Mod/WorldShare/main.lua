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
NPL.load('(gl)script/ide/System/Windows/Window.lua')

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

-- include aries create game movie
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua")

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

--  include aries creator game entity
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");

-- include worldshare service
NPL.load('(gl)Mod/WorldShare/service/SocketService.lua')
NPL.load('(gl)Mod/WorldShare/service/Cef3Manager.lua')


-- get table lib
local SocketService = commonlib.gettable('Mod.WorldShare.service.SocketService')
local Cef3Manager = commonlib.gettable('Mod.WorldShare.service.Cef3Manager')

-- bottles
local UserConsole = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/Main.lua')
local KickOut = NPL.load('(gl)Mod/WorldShare/cellar/Common/KickOut/KickOut.lua')
local SyncMain = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Main.lua')
local HistoryManager = NPL.load('(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua')
local PreventIndulge = NPL.load('(gl)Mod/WorldShare/cellar/PreventIndulge/PreventIndulge.lua')
local Beginner = NPL.load('(gl)Mod/WorldShare/cellar/Beginner/Beginner.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')
local LocalServiceSession = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')

-- helper
local Store = NPL.load('(gl)Mod/WorldShare/store/Store.lua')
local MsgBox = NPL.load('(gl)Mod/WorldShare/cellar/Common/MsgBox/MsgBox.lua')
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')

-- command
local WorldShareCommand = NPL.load('(gl)Mod/WorldShare/command/Command.lua')

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

            KickOut:ShowKickOutPage(reason)
        end
    end)

    WorldShareCommand:Init()
end

function WorldShare:OnInitDesktop()
end

function WorldShare:OnLogin()
end

function WorldShare:OnWorldLoad()
    if System.options.loginmode ~= 'offline' then
        -- open from MainLogin:EnterUserConsole
        Mod.WorldShare.MsgBox:Close()
    end

    UserConsole:ClosePage()

    -- local curLesson = Store:Getter('lesson/GetCurLesson')
    -- if enter with lesson method, we will not check revision
    -- if not curLesson then
    -- end
    
    SyncMain:OnWorldLoad()
    HistoryManager:OnWorldLoad()
    WorldShareCommand:OnWorldLoad()
    -- Beginner:OnWorldLoad()
    LocalServiceSession:OnWorldLoad()
    KeepworkServiceProject:OnWorldLoad()

    EventTrackingService:Send(2, 'duration.world.stay', { started = true })

    Mod.WorldShare.Store:Set('world/isEnterWorld', true)
    Mod.WorldShare.Store:Set('world/loadWorldFinish', true)
end

function WorldShare:OnWillLeaveWorld()
    LocalServiceSession:OnWillLeaveWorld()
end

function WorldShare:OnLeaveWorld()
    Store:Set('world/loadWorldFinish', false)

    local isEnterWorld = Mod.WorldShare.Store:Get('world/isEnterWorld')

    if isEnterWorld then
        EventTrackingService:Send(2, 'duration.world.stay', { ended = true })
        EventTrackingService:Send(2, 'duration.world.edit', { ended = true })
        EventTrackingService:Send(2, 'duration.world.play', { ended = true })
    end

    Store:Remove('world/currentWorld')
end
