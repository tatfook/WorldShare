--[[
Title: Opus Filter
Author(s): big
CreateDate: 2021.04.19
ModifyDate: 2021.11.14
Desc:
use the lib:
------------------------------------------------------------
local OpusFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Opus/OpusFilter.lua')
OpusFilter:Init()
------------------------------------------------------------
]]

-- bottles
local Opus = NPL.load('(gl)Mod/WorldShare/cellar/Opus/Opus.lua')

local OpusFilter = NPL.export()

function OpusFilter:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.opus.show',
        function(callback)
            Opus:Show()
        end
    )
end
