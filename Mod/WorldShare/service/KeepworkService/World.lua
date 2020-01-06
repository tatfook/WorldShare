--[[
Title: KeepworkService World
Author(s):  big
Date:  2019.12.9
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
------------------------------------------------------------
]]

local KeepworkService = NPL.load('../KeepworkService.lua')
local KeepworkWorldsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Worlds.lua")
local KeepworkProjectsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Projects.lua")

local KeepworkServiceWorld = NPL.export()

-- get world list
function KeepworkServiceWorld:GetWorldsList(callback)
    if not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkWorldsApi:GetWorldList(callback)
end

-- get world by worldname
function KeepworkServiceWorld:GetWorld(foldername, callback)
    if type(foldername) ~= 'string' or not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if type(callback) ~= 'function' or not data or not data[1] then
            return false
        end

        callback(data[1])
    end)
end

-- updat world info
function KeepworkServiceWorld:PushWorld(params, callback)
    if type(params) ~= 'table' or
       not params.worldName or
       not KeepworkService:IsSignedIn() then
        return false
    end

    self:GetWorld(
        params.worldName or '',
        function(world)
            local worldId = world and world.id or false

            if not worldId then
                return false
            end

            KeepworkWorldsApi:UpdateWorldinfo(worldId, params, callback)
        end
    )
end

-- get world by project id
function KeepworkServiceWorld:GetWorldByProjectId(kpProjectId, callback)
    if type(kpProjectId) ~= 'number' or kpProjectId == 0 then
        return false
    end

    KeepworkProjectsApi:GetProject(kpProjectId, function(data, err)
        if type(callback) ~= 'function' then
            return false
        end

        if err ~= 200 or not data or not data.world then
            callback(nil, err)
            return false
        end

        callback(data.world, err)
    end)
end