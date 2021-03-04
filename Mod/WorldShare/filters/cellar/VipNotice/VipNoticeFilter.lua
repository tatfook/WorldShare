--[[
Title: Vip Notice Filter
Author(s):  Big
Date: 2021.1.7
Desc: 
use the lib:
------------------------------------------------------------
local VipNoticeFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/MySchool/VipNoticeFilter.lua')
VipNoticeFilter:Init()
------------------------------------------------------------
]]

-- UI
local VipNotice = NPL.load("(gl)Mod/WorldShare/cellar/VipNotice/VipNotice.lua")

local VipNoticeFilter = NPL.export()

function VipNoticeFilter:Init()
    -- close vip notice page
    GameLogic.GetFilters():add_filter(
        'cellar.vip_notice.close',
        function()
            VipNotice:Close()
            return true
        end
    )
end