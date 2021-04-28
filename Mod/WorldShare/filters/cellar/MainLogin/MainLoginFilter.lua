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

-- libs
local RestartTable = commonlib.gettable('RestartTable')

-- UI
local MainLogin = NPL.load("(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua")

local MainLoginFilter = NPL.export()

function MainLoginFilter:Init()
    -- replace load world page
    GameLogic.GetFilters():add_filter(
        'cellar.main_login.show_login_mode_page',
        function()
            -- inject
            -- sync system.User info to Store user
            Mod.WorldShare.Store:Set('user/token', System.User.keepworktoken)
            Mod.WorldShare.Store:Set('user/username', RestartTable.username)
            Mod.WorldShare.Store:Set('user/whereAnonymousUser', RestartTable.whereAnonymousUser)

            MainLogin:Show()
            return false
        end
    )
end