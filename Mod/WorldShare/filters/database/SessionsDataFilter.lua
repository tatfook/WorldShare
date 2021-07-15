--[[
Title: Sessions Data Filter
Author(s):  Big
Date: 2021.6.9
Desc: 
use the lib:
------------------------------------------------------------
local SessionsDataFilter = NPL.load('(gl)Mod/WorldShare/filters/database/SessionsDataFilter.lua')
SessionsDataFilter:Init()
------------------------------------------------------------
]]

-- libs
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")

local SessionsDataFilter = NPL.export()

function SessionsDataFilter:Init()
    GameLogic.GetFilters():add_filter(
        'database.sessions_data.get_session_by_username',
        function(...)
            return SessionsData:GetSessionByUsername(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'database.sessions_data.save_session',
        function(...)
            return SessionsData:SaveSession(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'database.sessions_data.get_user_rice',
        function(...)
            -- return SessionsData:GetUserRice(...)
        end
    )

    GameLogic.GetFilters():add_filter(
        'database.sessions_data.set_user_rice',
        function(...)
            -- return SessionsData:SetUserRice(...)
        end
    )
end
