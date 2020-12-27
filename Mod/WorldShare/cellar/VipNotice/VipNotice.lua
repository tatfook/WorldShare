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
NPL.load("(gl)script/ide/System/Windows/Window.lua");
local Window = commonlib.gettable("System.Windows.Window");
local VipNotice = NPL.export()

VipNotice.TypeNames = {
    a_school_management_system = L"马上开通会员激活功能",
    t_online_teaching = L"马上开通会员激活功能",
    s_online_learning = L"马上开通会员激活功能",
    vip_world_data_save_as = L"马上开通会员激活功能",
    vip_skin_of_all_protagonists = L"开通会员激活全部皮肤",
    vip_python_code_block = L"开通会员使用Python方块",
    vip_video_plugin_watermark_removal = L"开通会员去除视频水印",
    vip_lan_40_people_online = L"开通会员扩展联网人数",
    vip_wan_networking = L"开通会员组建互联网服务器",
    vip_online_world_data_50mb = L"开通会员存储大型作品",
    MakeApp = L"开通会员创建自己的App",
    ChangeAvatarSkin = L"开通会员尽享精彩形象",
    t_create_vip_world = L"开通会员创建特殊权限世界",
    vip_code_game_art_of_war = L"开通会员畅享玩学课堂",
    vip_weekly_training = L"马上开通会员激活功能",
    daily_note = L"开通会员随意观看每日成长视频",
    fly_on_paraworld = L"开通会员马上飞行!",
}
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
    local width = 750;
	local height = 530;
	if(not VipNotice.window) then
		local window = Window:new();
		window:EnableSelfPaint(true);
		window:SetAutoClearBackground(true);
		VipNotice.window = window;
	end
	VipNotice.window:SetCanDrag(true);
	VipNotice.window:Show({
		name="VipNotice", 
		url="Mod/WorldShare/cellar/VipNotice/VipNotice.html",
		alignment="_ct", left=-width/2, top=-height/2, width = width, height = height, zorder = 1,
	});

   --Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/VipNotice/VipNotice.html", "VipNotice", 0, 0, "_fi", false, 0)
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.funnel.open', { from = self.from })
end

function VipNotice:RefreshVipInfo()
    UserInfo:LoginWithToken(VipNotice.callback);
end

function VipNotice:Close()
    if VipNotice.window then
        VipNotice.window:CloseWindow(true)
        VipNotice.window = nil
    end
end

function VipNotice:GetQRCode()
    local qrcode = string.format("%s/p/qr/purchase?userId=%s&from=%s",KeepworkService:GetKeepworkUrl(), Mod.WorldShare.Store:Get('user/userId'), VipNotice.from);
    return qrcode;
end

function VipNotice:GetTypeName()
    return VipNotice.TypeNames[VipNotice.from] or L"此功能需要开通会员";
end