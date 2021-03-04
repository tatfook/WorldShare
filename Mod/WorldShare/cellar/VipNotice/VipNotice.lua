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
--lib
local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");

local VipNotice = NPL.export()
local page

function VipNotice:InitUI()
    page = document:GetPageCtrl(); 
end

function VipNotice:ShowPage(key, desc)  
    local width = 784
    local height = 536
    self.key = key
    self.desc = desc
    Mod.WorldShare.Utils.ShowWindow(width, height, "Mod/WorldShare/cellar/VipNotice/VipNotice.html", "VipNotice", width, height ,"_ct", true, 1)
    VipNotice:InitQRCode()
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.funnel.open', { from = key })
end

function VipNotice:Close()
    if page then
        page:CloseWindow()
    end
end

function VipNotice:GetQRCodeUrl()
    local qrcode_url = string.format(
        '%s/p/qr/purchase?userId=%s&from=%s',
        KeepworkService:GetKeepworkUrl(),
        Mod.WorldShare.Store:Get('user/userId'),
        self.key
    )
    return qrcode_url
end

function VipNotice:InitQRCode()
    local parent  = page:GetParentUIObject()
    local ret,qrcode = QREncode.qrcode(VipNotice:GetQRCodeUrl())
    if ret then        
        local qrcode_width = 118
        local qrcode_height = 118
        local block_size = qrcode_width / #qrcode
        local qrcode_ui = ParaUI.CreateUIObject("container", "qrcode", "_lt", 70, 70, qrcode_width, qrcode_height);
        qrcode_ui:SetField("OwnerDraw", true); -- enable owner draw paint event
        qrcode_ui:SetField("SelfPaint", true);
        qrcode_ui:SetScript("ondraw", function(test)
            for i = 1, #(qrcode) do
                for j = 1, #(qrcode[i]) do
                    local code = qrcode[i][j];
                    if (code < 0) then
                        ParaPainter.SetPen("#000000ff");
                        ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                    end
                end
            end            
        end);
        parent:AddChild(qrcode_ui);
    end
end

function VipNotice:GetTypeName()
    return self.desc
end