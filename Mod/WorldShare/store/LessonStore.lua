--[[
Title: lesson store
Author(s): big
CreateDate: 2018.11.9
ModifyDate: 2022.6.28
use the lib:
------------------------------------------------------------
local LessonStore = NPL.load('(gl)Mod/WorldShare/store/LessonStore.lua')
------------------------------------------------------------
]]

local LessonStore = NPL.export()

function LessonStore:Action()
    return {
        SetCurLesson = function(curLesson)
            self.curLesson = curLesson
        end
    }
end

function LessonStore:Getter()
    return {
        GetCurLesson = function(curLesson)
            return self.curLesson
        end
    }
end