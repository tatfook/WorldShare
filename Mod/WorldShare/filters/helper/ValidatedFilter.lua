--[[
Title: Validated Filter
Author(s): big
CreateDate: 2022.8.11
Desc: 
use the lib:
------------------------------------------------------------
local ValidatedFilter = NPL.load('(gl)Mod/WorldShare/filters/helper/ValidatedFilter.lua')
ValidatedFilter:Init()
------------------------------------------------------------
]]

local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

local ValidatedFilter = NPL.export()

function ValidatedFilter:Init()
    GameLogic.GetFilters():add_filter(
        'helper.validated.phone',
        function(...)
            return Validated:Phone(...)
        end
    )
end
