--[[
Title: Kick Out Page
Author(s):  big
Date: 2021.2.3
Desc: 
use the lib:
------------------------------------------------------------
local KickOut = NPL.load("(gl)Mod/WorldShare/cellar/Common/KickOut/KickOut.lua")
------------------------------------------------------------
]]

-- libs
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local KickOut = NPL.export()

function KickOut:ShowKickOutPage(reason)
    if self.isKickOutPageOpened then
        return false
    end

    self.isKickOutPageOpened = true

    if KeepworkServiceSession:IsSignedIn() then
        -- OnKeepWorkLogout
        KeepworkServiceSession:Logout('KICKOUT', function()
            NplBrowserPlugin.CloseAllBrowsers()
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
        end)
    else
        -- OnKeepWorkLogout
        GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", false)
    end

    Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/Common/KickOut/KickOut.html?reason=" .. reason or 1, "Mod.WorldShare.Common.KickOut", 0, 0, "_fi", false, 1000)
end