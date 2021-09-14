--[[
Title: SyncToDataSourceFilter
Author(s): big
CreateDate: 2021.09.14
Desc: 
use the lib:
------------------------------------------------------------
local SyncToDataSourceFilter = NPL.load('(gl)Mod/WorldShare/filters/service/SyncService/SyncToDataSourceFilter.lua')
------------------------------------------------------------
]]

-- libs
local SyncToDataSource = NPL.load('(gl)Mod/WorldShare/service/SyncService/SyncToDataSource.lua')

local SyncToDataSourceFilter = NPL.export()

function SyncToDataSourceFilter:Init()
    GameLogic.GetFilters():add_filter(
        'service.sync_to_data_source.init',
        function(...)
            return SyncToDataSource:Init(...)
        end
    )
end
