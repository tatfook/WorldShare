--[[
Title: Sync Main Filter
Author(s):  Big
Date: 2021.4.29
Desc: 
use the lib:
------------------------------------------------------------
local SyncMainFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Sync/SyncMainFilter.lua')
SyncMainFilter:Init()
------------------------------------------------------------
]]

-- UI
local SyncMain = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Main.lua')

local SyncMainFilter = NPL.export()

function SyncMainFilter:Init()
    -- sync to data source by world name
    GameLogic.GetFilters():add_filter(
        'cellar.sync.sync_main.sync_to_data_source_by_world_name',
        function(...)
            SyncMain:SyncToDataSourceByWorldName(...)
        end
    )
end