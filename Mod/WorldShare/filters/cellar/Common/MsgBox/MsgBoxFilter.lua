--[[
Title: Msg Box Filter
Author(s):  Big
Date: 2021.1.25
Desc: 
use the lib:
------------------------------------------------------------
local MsgBoxFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Common/MsgBox/MsgBoxFilter.lua')
MsgBoxFilter:Init()
------------------------------------------------------------
]]

-- bottles
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox/MsgBox.lua")

local MsgBoxFilter = NPL.export()

function MsgBoxFilter:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.common.msg_box.show',
        function(...)
            MsgBox:Show(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'cellar.common.msg_box.close',
        function(...)
            MsgBox:Close(...)
        end
    )
end