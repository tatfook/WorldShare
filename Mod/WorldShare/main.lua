--[[
Title: WorldShareMod
Author(s): big
CreateDate: 2017.4.17
ModifyDate: 2022.6.28
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

-- include worldshare service
NPL.load('(gl)Mod/WorldShare/service/SocketService.lua')

-- get table lib
local SocketService = commonlib.gettable('Mod.WorldShare.service.SocketService')
local MainLogin = commonlib.gettable('MyCompany.Aries.Game.MainLogin')
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")

-- bottles
local KickOut = NPL.load('(gl)Mod/WorldShare/cellar/Common/KickOut/KickOut.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local OpusSetting = NPL.load('(gl)Mod/WorldShare/cellar/OpusSetting/OpusSetting.lua')
local PreventIndulge = NPL.load('(gl)Mod/WorldShare/cellar/PreventIndulge/PreventIndulge.lua')
local Certificate = NPL.load('(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua')
local Cellar = NPL.load('(gl)Mod/WorldShare/cellar/cellar.lua')
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')
local LocalServiceSession = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')

-- database
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

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
WorldShare:Property({'Desc', 'World share mod can share world to keepwork online', 'GetDesc', 'SetDesc', { auto = true }})

if Config.defaultEnv == 'RELEASE' or Config.defaultEnv == 'STAGE' then
    System.options.isAB_SDK = true
end

-- register mod global variable
WorldShare.Store = Store
WorldShare.MsgBox = MsgBox
WorldShare.Utils = Utils

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

    -- init long tcp connection
    KeepworkServiceSession:LongConnectionInit(function(result)
        if not result or type(result) ~= 'table' then
            return
        end

        if result.action == 'kickOut' then
            local reason = 1

            if result.payload and result.payload.reason then
                reason = result.payload.reason
            end

            KickOut:ShowKickOutPage(reason)
        elseif result.action == 'msg' then
            if result.payload.action == 'parentPhoneVerification' then
                Mod.WorldShare.Store:Action('user/ParentPhoneVerification')(result.payload)
            end
        end
    end)

    WorldShareCommand:Init()

    -- prevent autoupdate if local school version
    local localVersion = ParaEngine.GetAppCommandLineByParam('localVersion', nil)

    if localVersion then
        MainLogin.state.IsUpdaterStarted = true
    end

    -- load diff world
    -- Mod.WorldShare.Utils.SetTimeOut(function()
    --     NPL.load('(gl)Mod/DiffWorld/main.lua')
    --     local DiffWorld = commonlib.gettable('Mod.DiffWorld')

    --     if DiffWorld and type(DiffWorld) == 'table' and DiffWorld.init then
    --         DiffWorld:init()
    --     end
    -- end, 3000)

    System.options.useFreeworldWhitelist = true
    System.options.maxFreeworldUploadCount = 3

    -- GameLogic.GetFilters():add_filter('CheckInstallUrlProtocol', function()
    --     local sessions = SessionsData:GetSessions()

    --     if not sessions or not sessions.allUsers then
    --         return false
    --     else
    --         return true
    --     end
    -- end)

    if ParaEngine.GetAppCommandLineByParam('IsSettingLanguage', nil) == 'true' and
        Mod.WorldShare.Store:Get('user/isSettingLanguage') == nil then
        Mod.WorldShare.Store:Set('user/isSettingLanguage', true)
    end
end

function WorldShare:OnInitDesktop()
end

function WorldShare:OnLogin()
end

function WorldShare:OnWorldLoad()
    if KeepworkServiceSession:IsSignedIn() then
        -- open from MainLogin:Next
        Mod.WorldShare.MsgBox:Close()
    end

    SyncWorld:OnWorldLoad(function()
        Mod.WorldShare.Store:Set('world/loadWorldFinish', true)

        -- need to get current enter world info
        OpusSetting:OnWorldLoad()

        -- ensure current enter world exist
        local entityPlayer = EntityManager.GetFocus()

        if entityPlayer then
            local x, y, z = entityPlayer:GetBlockPos()
            local position = { x = x, y = y, z = z }

            EventTrackingService:Send(2, 'duration.world.stay', { started = true, position = position })
        else
            EventTrackingService:Send(2, 'duration.world.stay', { started = true })
        end


        
        GameLogic.GetFilters():apply_filters('set_mode', GameLogic.GameMode:GetMode())
    end)

    WorldShareCommand:OnWorldLoad()
    LocalServiceSession:OnWorldLoad()
    KeepworkServiceProject:OnWorldLoad()
    KeepworkServiceSession:OnWorldLoad()
    Certificate:OnWorldLoad()
    CommonLoadWorld:OnWorldLoad()

    Mod.WorldShare.Store:Set('world/isEnterWorld', true)
end

function WorldShare:OnWillLeaveWorld()
    LocalServiceSession:OnWillLeaveWorld()
    KeepworkServiceSession:OnWillLeaveWorld()
end

function WorldShare:OnLeaveWorld()
    Store:Set('world/loadWorldFinish', false)

    local isEnterWorld = Mod.WorldShare.Store:Get('world/isEnterWorld')

    if isEnterWorld then
        local entityPlayer = EntityManager.GetFocus()

        if entityPlayer then
            local x, y, z = entityPlayer:GetBlockPos()
            local position = { x = x, y = y, z = z }

            EventTrackingService:Send(2, 'duration.world.stay', { ended = true, position = position })
        else
            EventTrackingService:Send(2, 'duration.world.stay', { ended = true })
        end

        EventTrackingService:Send(2, 'duration.world.edit', { ended = true })
        EventTrackingService:Send(2, 'duration.world.play', { ended = true })
    end

    Store:Remove('world/currentWorld')
end
