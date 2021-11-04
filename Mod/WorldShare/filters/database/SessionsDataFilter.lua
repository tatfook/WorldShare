--[[
Title: Sessions Data Filter
Author(s): big
CreateDate: 2021.06.09
ModifyDate: 2021.11.04
Desc: 
use the lib:
------------------------------------------------------------
local SessionsDataFilter = NPL.load('(gl)Mod/WorldShare/filters/database/SessionsDataFilter.lua')
SessionsDataFilter:Init()
------------------------------------------------------------
]]

-- libs
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

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
        'database.sessions_data.get_sessions',
        function()
            return SessionsData:GetSessions()
        end
    )
end
