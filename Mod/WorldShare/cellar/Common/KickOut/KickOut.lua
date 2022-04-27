--[[
Title: Kick Out Page
Author(s):  big
Date: 2021.2.3
Desc: 
use the lib:
------------------------------------------------------------
local KickOut = NPL.load('(gl)Mod/WorldShare/cellar/Common/KickOut/KickOut.lua')
------------------------------------------------------------
]]

-- libs
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local KickOut = NPL.export()

function KickOut:ShowKickOutPage(reason)
    -- 修改密码之后的退出 由接口返回的回调来处理
    if reason == 2 then
        return
    end

    if self.isKickOutPageOpened then
        return false
    end

    self.isKickOutPageOpened = true

    NplBrowserPlugin.CloseAllBrowsers()

    Mod.WorldShare.MsgBox:Show(L'您的账号已经在其他地方登录，正在登出...', nil, nil, 460, nil, 1000)
    Mod.WorldShare.Utils.SetTimeOut(function()
        Mod.WorldShare.MsgBox:Close()

        if KeepworkServiceSession:IsSignedIn() then
            -- OnKeepWorkLogout
            KeepworkServiceSession:Logout('KICKOUT', function()
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
            end)
        else
            -- OnKeepWorkLogout
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", false)
        end
    
        Mod.WorldShare.Utils.ShowWindow(
            0,
            0,
            'Mod/WorldShare/cellar/Common/KickOut/KickOut.html?reason=' .. reason or 1,
            'Mod.WorldShare.Common.KickOut',
            0,
            0,
            '_fi',
            false,
            10000
        )
    end, 2000)
end