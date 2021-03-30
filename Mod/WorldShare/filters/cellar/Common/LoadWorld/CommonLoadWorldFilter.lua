--[[
Title: Common Load World Filter
Author(s):  big
Date: 2021.3.30
Desc: 
use the lib:
------------------------------------------------------------
local CommonLoadWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Common/LoadWorld/CommonLoadWorldFilter.lua')
CommonLoadWorldFilter:Init()
------------------------------------------------------------
]]

-- bottles
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')

local CommonLoadWorldFilter = NPL.export()

function CommonLoadWorldFilter:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.common.common_load_world.enter_course_world',
        function(...)
            CommonLoadWorld:EnterCourseWorld(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'cellar.common.common_load_world.enter_homework_world',
        function(...)
            CommonLoadWorld:EnterHomeworkWorld(...)
        end
    )
end
