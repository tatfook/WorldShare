--[[
Title: filters
Author(s):  Big
Date: 2020.12.11
Desc: 
use the lib:
------------------------------------------------------------
local Filters = NPL.load('(gl)Mod/WorldShare/filters/Filters.lua')
Filters:Init()
------------------------------------------------------------
]]

-- load all filters
local Session = NPL.load('./service/KeepworkService/Session.lua')

local Filters = NPL.export()

function Filters:Init()
    -- init session filter
    Session:Init()
end