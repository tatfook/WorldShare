--[[
Title: Session
Author(s):  Big
Date: 2020.12.11
Desc: 
use the lib:
------------------------------------------------------------
local Session = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/Session.lua')
Session:Init()
------------------------------------------------------------
]]

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local Session = NPL.export()

function Session:Init()
    -- filter is real name
    GameLogic.GetFilters():add_filter(
        'service.session.is_real_name',
        function()
            return KeepworkServiceSession:IsRealName()
        end
    )
end