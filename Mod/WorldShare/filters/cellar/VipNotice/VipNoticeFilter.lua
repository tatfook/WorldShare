--[[
Title: MySchool
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
    -- vip notice init
    -- from 表示VIP的功能入口，必填
    GameLogic.GetFilters():add_filter(
        'cellar.vip_notice.init',
        function(bEnabled, from, callback)
            VipNotice:Init(bEnabled, from, callback)
            return true
        end
    )

    -- [DEPRECATED] we will remove in the future
    GameLogic.GetFilters():add_filter(
        'VipNotice',
        function(bEnabled, from, callback)
            VipNotice:Init(bEnabled, from, callback)
            return true
        end
    )

    -- close vip notice page
    GameLogic.GetFilters():add_filter(
        'cellar.vip_notice.close',
        function()
            VipNotice:Close()
            return true
        end
    )
end