--[[
Title: Client Update Dialog Filter
Author(s):  Big
Date: 2021.1.25
Desc: 
use the lib:
------------------------------------------------------------
local ClientUpdateDialogFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/ClientUpdateDialog/ClientUpdateDialogFilter.lua')
ClientUpdateDialogFilter:Init()
------------------------------------------------------------
]]

-- UI
local ClientUpdateDialog = NPL.load("(gl)Mod/WorldShare/cellar/ClientUpdateDialog/ClientUpdateDialog.lua")

local ClientUpdateDialogFilter = NPL.export()

function ClientUpdateDialogFilter:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.client_update_dialog.show',
        function(bEnabled, updater, gamename)
            ClientUpdateDialog:Show(updater, gamename)
            return true
        end
    )
end