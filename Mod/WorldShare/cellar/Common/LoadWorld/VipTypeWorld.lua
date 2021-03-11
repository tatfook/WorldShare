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
    if world.isVipWorld then
        return true
    else
        return false
    end
end

function VipTypeWorld:CheckVipWorld(world, callback)
    if not world or type(world) ~= 'table' then
        return false
    end

    if world.isVipWorld then
        if not KeepworkServiceSession:IsSignedIn() then
            return false
        end

        local canEnter = false
        local username = Mod.WorldShare.Store:Get('user/username')

        if world.user and world.user.username == username then
            canEnter = true
        end

        local isVip = Mod.WorldShare.Store:Get('user/isVip')

        if isVip then
            canEnter = true
        end

        if not canEnter then
            return false
        end

        return canEnter
    else
        return true
    end
end

function VipTypeWorld:IsInstituteVipWorld(world)
    if world.instituteVipEnabled then
        return true
    else
        return false
    end
end

function VipTypeWorld:CheckInstituteVipWorld(world, callback)
    if not world or type(world) ~= 'table' then
        return false
    end

    if world.instituteVipEnabled then
        if not KeepworkServiceSession:IsSignedIn() then
            if callback and type(callback) == 'function' then
                callback(false)
            end
            return
        end

        GameLogic.IsVip('IsOrgan', true, function(result)
            if result then
                if callback and type(callback) == 'function' then
                    callback(true)
                end
            else
                if callback and type(callback) == 'function' then
                    callback(false)
                end
            end
        end, 'Institute')
    else
        if callback and type(callback) == 'function' then
            callback(false)
        end
    end
end