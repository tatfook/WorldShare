--[[
Title: Keepwork Service Session Filter
Author(s):  Big
Date: 2020.12.11
Desc: 
use the lib:
------------------------------------------------------------
local KeepworkServiceSessionFilter = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/KeepworkServiceSessionFilter.lua')
KeepworkServiceSessionFilter:Init()
------------------------------------------------------------
]]

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local KeepworkServiceSessionFilter = NPL.export()

function KeepworkServiceSessionFilter:Init()
    -- filter is real name
    GameLogic.GetFilters():add_filter(
        'service.session.is_real_name',
        function()
            return KeepworkServiceSession:IsRealName()
        end
    )

    -- filter get user where
    GameLogic.GetFilters():add_filter(
        'service.session.get_user_where',
        function()
            return KeepworkServiceSession:GetUserWhere()
        end
    )
end