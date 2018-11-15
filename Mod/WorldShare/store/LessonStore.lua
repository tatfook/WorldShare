--[[
Title: lesson store
Author(s):  big
Date:  2018.11.9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/store/Page.lua")
local PageStore = commonlib.gettable('Mod.WorldShare.store.Page')
------------------------------------------------------------
]]

local LessonStore = commonlib.gettable('Mod.WorldShare.store.Lesson')

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