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
-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

-- UI
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")

local VipNotice = NPL.export()

VipNotice.onlyRecharge = false;

function VipNotice:Init(bEnable, from, callback)
    VipNotice.callback = callback
    VipNotice.from = from;
    if not KeepworkService:IsSignedIn() then
        Mod.WorldShare.Store:Set("user/loginText", L"您需要登录并成为VIP用户，才能使用此功能")
        LoginModal:Init(function(bSuccesed)
            if bSuccesed then
                self:CheckVip(bEnable)
            end
        end)
    else
        self:CheckVip(bEnable)
    end
end

function VipNotice:CheckVip(bEnable)
    if (not Mod.WorldShare.Store:Get('user/isVip') or bEnable) then
        VipNotice.onlyRecharge = bEnable;
        self:ShowPage()
    else
        if type(self.callback) == "function" then
            VipNotice.callback()
        end
    end
end

function VipNotice:ShowPage()
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.vip_popup')
    NPL.load("(gl)Mod/WorldShare/cellar/VipNotice/QRCodeWnd.lua");
    self.QRCodeWnd = commonlib.gettable("Mod.WorldShare.cellar.VipNotice.QRCodeWnd");
    self.QRCodeWnd:Show();
    
    local params = {
		url = "Mod/WorldShare/cellar/VipNotice/VipNotice.html", 
		name = "VipNotice.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		click_through = false, 
		bShow = true,
		isTopLevel = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -700/2,
			y = -570/2,
			width = 700,
			height = 570,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    
    --Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/VipNotice/VipNotice.html", "VipNotice", 0, 0, "_fi", false, 0)
end

function VipNotice:RefreshVipInfo()
    UserInfo:LoginWithToken(VipNotice.callback);
end

function VipNotice:Close()
    self.QRCodeWnd:Hide();
end

function VipNotice:GetQRCode()
    local qrcode = string.format("%s/p/qr/purchase?userId=%s&from=%s",KeepworkService:GetKeepworkUrl(), Mod.WorldShare.Store:Get('user/userId'), VipNotice.from);
    return qrcode;
end