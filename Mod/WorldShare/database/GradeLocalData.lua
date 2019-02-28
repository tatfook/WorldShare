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

function GradeLocalData:IsProjectIdExist(projectId, username)
    projectId = tonumber(projectId) or false

    if not projectId or not username then
        return false
    end

    local userProjectIds = self:GetData('userProjectIds')

    if type(userProjectIds) ~= 'table' then
        return false
    end

    for key, item in ipairs(userProjectIds) do
        if item and item.username and item.projectId then
            if item.username == username and item.projectId == projectId then
                return true
            end
        end
    end

    return false
end

function GradeLocalData:RecordProjectId(projectId, username)
    projectId = tonumber(projectId) or false

    if not projectId or not username then
        return false
    end

    local userProjectIds = self:GetData('userProjectIds')

    if type(userProjectIds) ~= 'table' then
        userProjectIds = {}
    end

    if self:IsProjectIdExist(projectId, username) then
        return false
    end

    userProjectIds[#userProjectIds + 1] = {
        username = username,
        projectId = projectId
    }

    self:SetData('userProjectIds', userProjectIds)

    return true
end