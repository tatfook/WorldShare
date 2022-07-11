--[[
Title: Local Service Session
Author(s):  big
Date:  2021.1.30
Place: Foshan
use the lib:
------------------------------------------------------------
local LocalServiceSession = NPL.load("(gl)Mod/WorldShare/service/LocalService/LocalServiceSession.lua")
------------------------------------------------------------
]]

-- database
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

-- libs
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")

local LocalServiceSession = NPL.export()

function LocalServiceSession:OnWorldLoad()
    Mod.WorldShare.Store:Remove('world/isShowExitPage')

    -- for strange issue
    -- if GameLogic.options:IsCommunityWorld() then
    --     if not KeepworkServiceSession:IsSignedIn() then
    --         return
    --     end

    --     -- go to user last position
    --     local userLastPosition = SessionsData:GetUserLastPosition()

    --     if userLastPosition and type(userLastPosition) == 'table' then
    --         GameLogic.RunCommand(
    --             format(
    --                 '/goto %d, %d, %d',
    --                 userLastPosition.position.x,
    --                 userLastPosition.position.y,
    --                 userLastPosition.position.z
    --             )
    --         )

    --         GameLogic.RunCommand(format('/camerapitch %s', userLastPosition.orientation.cameraLiftupAngle))
    --         GameLogic.RunCommand(format('/camerayaw %s', userLastPosition.orientation.cameraRotY))
    --     end
    -- end
end

function LocalServiceSession:OnWillLeaveWorld()
    -- record last enter world
    local lastWorld = Mod.WorldShare.Store:Get('world/lastWorld')
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if (not lastWorld or lastWorld.foldername ~= currentEnterWorld.foldername) and not Mod.WorldShare.Store:Get('world/reloadStatus') then
        Mod.WorldShare.Store:Set('world/lastWorld', Mod.WorldShare.Store:Get('world/currentEnterWorld'))
    end

    if Mod.WorldShare.Store:Get('world/reloadStatus') then
        Mod.WorldShare.Store:Remove('world/reloadStatus')
    end

    -- set actor last position
    -- for strange issue
    -- if GameLogic.options:IsCommunityWorld() then
    --     if not KeepworkServiceSession:IsSignedIn() or not Mod.WorldShare.Store:Get('world/isEnterWorld') then
    --         return
    --     end
    
    --     -- get user position info
    --     local cameraAttribute = ParaCamera.GetAttributeObject()
    --     local cameraLiftupAngle = cameraAttribute:GetField('CameraLiftupAngle')
    --     local cameraRotY = cameraAttribute:GetField('CameraRotY')
    
    --     local focusEntity = EntityManager.GetFocus()
    
    --     if not focusEntity then
    --         return
    --     end
    
    --     local x, y, z = focusEntity:GetBlockPos()
    
    --     SessionsData:SetUserLastPosition(x, y, z, cameraLiftupAngle, cameraRotY)
    -- end
end

