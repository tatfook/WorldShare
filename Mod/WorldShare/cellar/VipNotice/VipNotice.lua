--[[
Title: VersionNotice
Author(s):  big
Date: 2020.01.14
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VipNotice = NPL.load("(gl)Mod/WorldShare/cellar/VipNotice/VipNotice.lua")
------------------------------------------------------------
]]

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")

local VipNotice = NPL.export()

function VipNotice:Init(callback)
    self.callback = callback

    if not KeepworkService:IsSignedIn() then
        Mod.WorldShare.Store:Set("user/loginText", L"您需要登录并成为VIP用户，才能使用此功能")
        LoginModal:Init(function(bSuccesed)
            if bSuccesed then
                self:CheckVip()
            end
        end)
    else
        self:CheckVip()
    end
end

function VipNotice:CheckVip()
    if not Mod.WorldShare.Store:Get('user/isVip') then
        self:ShowPage()
    else
        if type(self.callback) == "function" then
            self.callback()
        end
    end
end

function VipNotice:ShowPage()
    Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/VipNotice/VipNotice.html", "VipNotice", 0, 0, "_fi", false, 10)
end

function VipNotice:RefreshVipInfo()
    UserInfo:LoginWithToken();
end