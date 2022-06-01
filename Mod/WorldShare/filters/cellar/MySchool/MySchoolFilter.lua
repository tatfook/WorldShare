--[[
Title: MySchool
Author(s):  Big
Date: 2020.12.17
Desc: 
use the lib:
------------------------------------------------------------
local MySchoolFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/MySchool/MySchoolFilter.lua')
MySchoolFilter:Init()
------------------------------------------------------------
]]

-- UI
local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")

local MySchoolFilter = NPL.export()

function MySchoolFilter:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.my_school.select_school',
        function(callback)
            local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
            RedSummerCampCourseScheduling.CheckHasUnGraduationClasses(function(bool)
                if bool then
                    GameLogic.AddBBS(nil,L"你当前所在学校有课程未结业，暂时不可变更学校",nil,"255 0 0")
                else
                    MySchool:ShowJoinSchool(callback)
                end
            end)
        end
    )

    GameLogic.GetFilters():add_filter(
        'cellar.my_school.after_selected_school',
        function(callback)
            MySchool:Show(callback)
            return Mod.WorldShare.Store:Get('page/Mod.WorldShare.MySchool')
        end
    )
end