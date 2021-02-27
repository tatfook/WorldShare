--[[
Title: Main Login
Author(s):  Big
Date: 2021.2.25
Desc: 
use the lib:
------------------------------------------------------------
local MainLoginFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/MainLogin/MainLoginFilter.lua')
MainLoginFilter:Init()
------------------------------------------------------------
]]

-- UI
local MainLogin = NPL.load("(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua")

local MainLoginFilter = NPL.export()

function MainLoginFilter:Init()
    -- replace load world page
    GameLogic.GetFilters():add_filter(
        'cellar.main_login.show_login_mode_page',
        function()
            MainLogin:Show()
            return false
        end
    )
end