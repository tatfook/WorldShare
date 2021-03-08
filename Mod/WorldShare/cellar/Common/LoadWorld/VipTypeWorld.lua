--[[
Title: Vip Type World
Author(s): big
Date: 2021.3.8
City: Foshan
use the lib:
------------------------------------------------------------
local VipTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/VipTypeWorld.lua')
------------------------------------------------------------
]]

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local VipTypeWorld = NPL.export()

function VipTypeWorld:IsVipWorld(world)
    if world.vipEnabled == 'true' or
       world.instituteVipEnabled == 'true' then
        return true
    else
        return false
    end
end

function VipTypeWorld:CheckVipWorld(world, callback)
    if not world or type(world) ~= 'table' then
        return false
    end

    if world.vipEnabled == 'true' or
       world.instituteVipEnabled == 'true' then
        if not KeepworkServiceSession:IsSignedIn() then
            return false
        end

        local canEnter = false
        local username = Mod.WorldShare.Store:Get('user/username')

        if world.user and world.user.username == username then
            canEnter = true
        end

        local isVip = Mod.WorldShare.Store:Get('user/isVip')

        if world.vipEnabled == 'true' then
            if isVip then
                canEnter = true
            end
        end

        local userType = Mod.WorldShare.Store:Get('user/userType')

        if world.instituteVipEnabled == 'true' then
            if userType.student then
                canEnter = true
            end
        end

        if not canEnter then
            _guihelper.MessageBox(L'你没有权限进入此世界')
            return false
        end

        return canEnter
    else
        return true
    end
end