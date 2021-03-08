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
            MySchool:ShowJoinSchool(callback)
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