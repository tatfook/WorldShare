--[[
Title: Grade
Author(s):  big
Date: 2019.01.16
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Grade = NPL.load("(gl)Mod/WorldShare/cellar/WorldExitDialog/Grade.lua")
------------------------------------------------------------
]]

local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local KeepworkServiceRate = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Rate.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua")
local GradeLocalData = NPL.load("(gl)Mod/WorldShare/database/GradeLocalData.lua")

local Grade = NPL.export()

Grade.score = 0
Grade.starTable = {{selected = false}, {selected = false}, {selected = false}, {selected = false}, {selected = false}}

function Grade:Init()
    Grade.score = 0
    Grade.starTable = {{selected = false}, {selected = false}, {selected = false}, {selected = false}, {selected = false}}
end

function Grade:UpdateScore(score, callback)
    local username = Mod.WorldShare.Store:Get('user/username')
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not username or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end

    if not score or score == 0 then
        return false
    end

    local rate = score * 20

    KeepworkServiceRate:SetRatedProject(
        currentWorld.kpProjectId,
        rate,
        function(data, err)
            if err == 200 then
                if type(callback) == 'function' then
                    callback()
                end
                -- GradeLocalData:RecordProjectId(KeepworkServiceProject:GetProjectId(), username)
            end
        end
    )
end

function Grade:IsRated(kpProjectId, callback)
    if not kpProjectId then
        return false
    end

    KeepworkServiceRate:GetRatedProject(
        tonumber(kpProjectId),
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if data and #data > 0 then
                callback(true)
            else
                callback(false)
            end
        end
    )
end

function Grade:GetScoreTable()
    return self.starTable
end