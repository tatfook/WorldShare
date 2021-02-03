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
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

-- libs
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")

local LocalServiceSession = NPL.export()

function LocalServiceSession:OnWorldLoad()
    if GameLogic.options:IsCommunityWorld() then
        if not KeepworkServiceSession:IsSignedIn() then
            return
        end

        -- go to user last position
        local userLastPosition = SessionsData:GetUserLastPosition()
        echo(userLastPosition, true)
        if userLastPosition and type(userLastPosition) == 'table' then
            GameLogic.RunCommand(
                format(
                    '/goto %d, %d, %d',
                    userLastPosition.position.x,
                    userLastPosition.position.y,
                    userLastPosition.position.z
                )
            )

            GameLogic.RunCommand(format('/camerapitch %s', userLastPosition.orientation.cameraLiftupAngle))
            GameLogic.RunCommand(format('/camerayaw %s', userLastPosition.orientation.cameraRotY))
        end
    end
end

function LocalServiceSession:OnWillLeaveWorld()
    -- record last enter world
    Mod.WorldShare.Store:Set('world/lastWorld', Mod.WorldShare.Store:Get('world/currentEnterWorld'))

    -- set actor last position
    if GameLogic.options:IsCommunityWorld() then
        if not KeepworkServiceSession:IsSignedIn() or not Mod.WorldShare.Store:Get('world/isEnterWorld') then
            return
        end
    
        -- get user position info
        local cameraAttribute = ParaCamera.GetAttributeObject()
        local cameraLiftupAngle = cameraAttribute:GetField('CameraLiftupAngle')
        local cameraRotY = cameraAttribute:GetField('CameraRotY')
    
        local focusEntity = EntityManager.GetFocus()
    
        if not focusEntity then
            return
        end
    
        local x, y, z = focusEntity:GetBlockPos()
    
        SessionsData:SetUserLastPosition(x, y, z, cameraLiftupAngle, cameraRotY)
    end
end

