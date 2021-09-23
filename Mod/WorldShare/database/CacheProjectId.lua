--[[
Title: Cache Project Id
Author(s): big
CreateDate: 2019.11.19
ModifyDate: 2021.09.23
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CacheProjectId = NPL.load('(gl)Mod/WorldShare/database/CacheProjectId.lua')
------------------------------------------------------------
]]

local CacheProjectId = NPL.export()

local projects = {}

function CacheProjectId:SetProjectIdInfo(pid, worldInfo)
    if type(pid) ~= 'number' or type(worldInfo) ~= 'table' then
        return false
    end

    local project = {
        pid = pid,
        worldInfo = worldInfo
    }

    projects[pid] = project

    GameLogic.GetPlayerController():SaveLocalData('pid' .. pid, project, true)
    return true
end

function CacheProjectId:GetProjectIdInfo(pid)
    if type(pid) ~= 'number' then
        return false
    end

    if projects[pid] then
        return projects[pid]
    else
        local project = GameLogic.GetPlayerController():LoadLocalData('pid' .. pid, nil, true)

        if project then
            projects[pid] = project
        end

        return project
    end
end