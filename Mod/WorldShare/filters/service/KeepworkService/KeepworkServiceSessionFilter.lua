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
    -- filter login width token
    GameLogic.GetFilters():add_filter(
        'login_with_token',
        function(...)
            KeepworkServiceSession:LoginWithToken(...)
        end
    )

    -- filter logout
    GameLogic.GetFilters():add_filter(
        'logout',
        function(mode, callback)
            KeepworkServiceSession:Logout(mode, callback);
        end
    )

    -- filter logout
    GameLogic.GetFilters():add_filter(
        'service.session.logout',
        function(...)
            return KeepworkServiceSession:Logout(...)
        end
    )

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