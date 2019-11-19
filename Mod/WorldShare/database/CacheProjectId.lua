--[[
Title: Cache Project Id
Author(s):  big
Date: 2019.11.19
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CacheProjectId = NPL.load("(gl)Mod/WorldShare/database/CacheProjectId.lua")
------------------------------------------------------------
]]

local CacheProjectId = NPL.export()

function CacheProjectId:GetCache()
    return GameLogic.GetPlayerController():LoadLocalData("projectIds", {}, true)
end

function CacheProjectId:SetProjectIdInfo(pid, worldInfo)
    local projectIds = self:GetCache()

    if type(pid) ~= 'number' or type(worldInfo) ~= 'table' then
        return false
    end

    for key, item in pairs(projectIds) do
        if item.pid == pid then
            return false
        end
    end

    projectIds[#projectIds + 1] = {
        pid = pid,
        worldInfo = worldInfo
    }

    GameLogic.GetPlayerController():SaveLocalData("projectIds", projectIds, true)

    return true
end

function CacheProjectId:GetProjectIdInfo(pid)
    local projectIds = self:GetCache()

    if type(pid) ~= 'number' then
        return false
    end
 
    for key, item in pairs(projectIds) do
        if item.pid == pid then
            return item
        end
    end

    return false
end