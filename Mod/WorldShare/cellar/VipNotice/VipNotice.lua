--[[
Title: VersionNotice
Author(s):  big
Date: 2020.01.14
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VipNotice = NPL.load('(gl)Mod/WorldShare/cellar/VipNotice/VipNotice.lua')
------------------------------------------------------------
]]
-- service
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')

-- UI
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local UserInfo = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua')

-- libs
local Window = commonlib.gettable('System.Windows.Window')

local VipNotice = NPL.export()

-- VipNotice.onlyRecharge = false;

-- from 表示VIP的功能入口，必填
function VipNotice:Init(bEnable, from, callback)
    -- local debug = ParaEngine.GetAppCommandLineByParam('debug', false);
    -- if(debug == true or debug =='true' or debug == 'True')then
    --     if (from == nil or from == '' or VipNotice.TypeNames[from] == nil) then
    --         _guihelper.MessageBox(string.format(L'VIP入口为无效值：%s 。', from));
    --         return;
    --     end
    -- end

    -- VipNotice.callback = callback
    -- VipNotice.from = from
    -- if not KeepworkService:IsSignedIn() then
    --     Mod.WorldShare.Store:Set('user/loginText', L'您需要登录并成为VIP用户，才能使用此功能')
    --     LoginModal:Init(function(bSuccesed)
    --         if bSuccesed then
    --             self:CheckVip(bEnable)
    --         end
    --     end)
    -- else
    --     self:CheckVip(bEnable)
    -- end
end

-- function VipNotice:CheckVip(bEnable)
--     if (not Mod.WorldShare.Store:Get('user/isVip') or bEnable) then
--         VipNotice.onlyRecharge = bEnable;
--         self:ShowPage()
--     else
--         if type(self.callback) == 'function' then
--             VipNotice.callback()
--         end
--     end
-- end

function VipNotice:ShowPage(key, desc)  
    local width = 750
    local height = 530

    self.key = key
    self.desc = desc
    
    if not VipNotice.window then
		local window = Window:new()
		window:EnableSelfPaint(true)
		window:SetAutoClearBackground(true)
		VipNotice.window = window
    end

    VipNotice.window:SetCanDrag(true)

	VipNotice.window:Show({
		name = 'Mod.WorldShare.VipNotice', 
		url = 'Mod/WorldShare/cellar/VipNotice/VipNotice.html',
        alignment = '_ct',
        left = -width / 2,
        top = -height / 2,
        width = width,
        height = height,
        zorder = 1,
    })

    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.funnel.open', { from = key })
end

-- function VipNotice:RefreshVipInfo()
--     UserInfo:LoginWithToken(VipNotice.callback);
-- end

function VipNotice:Close()
    if VipNotice.window then
        VipNotice.window:CloseWindow(true)
        VipNotice.window = nil
    end
end

function VipNotice:GetQRCode()
    local qrcode = string.format(
        '%s/p/qr/purchase?userId=%s&from=%s',
        KeepworkService:GetKeepworkUrl(),
        Mod.WorldShare.Store:Get('user/userId'),
        self.key
    )

    return qrcode
end

function VipNotice:GetTypeName()
    return self.desc
end