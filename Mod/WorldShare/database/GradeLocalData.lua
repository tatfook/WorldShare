--[[
Title: Grade Local Data
Author(s):  big
Date: 2019.01.19
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local GradeLocalData = NPL.load("(gl)Mod/WorldShare/database/GradeLocalData.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local GradeLocalData = NPL.export()

function GradeLocalData:GetAllData()
    local playerController = Store:Getter("user/GetPlayerController")

    if not playerController then
        playerController = GameLogic.GetPlayerController()
        local SetPlayerController = Store:Action("user/SetPlayerController")

        SetPlayerController(playerController)
    end

    local grade = playerController:LoadLocalData("grade", nil, true)

    if type(grade) ~= "table" then
        return {}
    end

    return grade
end

function GradeLocalData:GetData(key)
    local allData = self:GetAllData()

    if type(allData) ~= 'table' then
        return false
    end

    return allData[key]
end

function GradeLocalData:SetData(key, value)
    local allData = self:GetAllData()
    local playerController = Store:Getter("user/GetPlayerController")

    if not allData or not playerController then
        return false
    end

    allData[key] = value

    playerController:SaveLocalData("grade", allData, true)
end

function GradeLocalData:IsProjectIdExist(projectId)
    projectId = tonumber(projectId) or false

    if not projectId  then
        return false
    end

    local projectIds = self:GetData('projectIds')

    if type(projectIds) == 'table' and projectIds[projectId] then
        return true
    else
        return false
    end
end

function GradeLocalData:RecordProjectId(projectId)
    projectId = tonumber(projectId) or false

    if not projectId then
        return false
    end

    local projectIds = self:GetData('projectIds')

    if type(projectIds) ~= 'table' then
        projectIds = {}
    end

    projectIds[projectId] = projectId

    self:SetData('projectIds', projectIds)

    return true
end