--[[
Title: Keepwork Dragon Boat Api Filter
Author(s):  Big
Date: 2021.6.8
Desc: 
use the lib:
------------------------------------------------------------
local KeepworkDragonBoatApiFilter = NPL.load('(gl)Mod/WorldShare/filters/api/Keepwork/KeepworkDragonBoatApiFilter.lua')
KeepworkDragonBoatApiFilter:Init()
------------------------------------------------------------
]]

-- api
local KeepworkDragonBoatApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/DragonBoatApi.lua")

local KeepworkDragonBoatApiFilter = NPL.export()

function KeepworkDragonBoatApiFilter:Init()
    GameLogic.GetFilters():add_filter(
        'api.keepwork.dragon_boat.rice',
        function(...)
            KeepworkDragonBoatApi:Rice(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'api.keepwork.dragon_boat.process',
        function(...)
            KeepworkDragonBoatApi:Process(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'api.keepwork.dragon_boat.gifts',
        function(...)
            KeepworkDragonBoatApi:Gifts(...)
        end
    )
end