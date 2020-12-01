--[[
Title: Certificate
Author(s): big
Date: 2020.11.30
City: Foshan
use the lib:
------------------------------------------------------------
local Certificate = NPL.load("(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua")
------------------------------------------------------------
]]

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local Certificate = NPL.export()

Certificate.certificateCallback = nil

function Certificate:Init(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        GameLogic.AddBBS(nil, L"请先登录", 3000, "255 0 0")
        return
    end

    -- if KeepworkServiceSession:IsRealName() then
    --     if callback and type(callback) == 'function' then
    --         callback(true)
    --     end
    --     return
    -- end

    self.certificateCallback = callback

    self:ShowCertificatePage()
end

function Certificate:ShowCertificatePage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        800,
        450,
        '(ws)Certificate',
        'Mod.WorldShare.Certificate'
    )

    if params and type(params) == 'table' and params._page then
        params._page.CertificateNow = function() self:ShowCertificateTypePage() end
        params._page.certificateCallback = self.certificateCallback
    end
end

function Certificate:ShowCertificateTypePage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        700,
        480,
        '(ws)/Certificate/CertificateType.html',
        'Mod.WorldShare.Certificate.CertificateType'
    )

    if params and type(params) == 'table' and params._page then
        params._page.SelSchool = function() self:ShowSchoolPage() end
        params._page.SelMyHome = function() self:ShowMyHomePage() end
        params._page.certificateCallback = self.certificateCallback
    end
end

function Certificate:ShowSchoolPage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        800,
        680,
        '(ws)Certificate/School.html',
        'Mod.WorldShare.Certificate.School'
    )

    if params and type(params) == 'table' and params._page then
        params._page.Success = function() self:ShowSendSmsPage() end
        params._page.certificateCallback = self.certificateCallback
    end
end

function Certificate:ShowMyHomePage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        800,
        670,
        '(ws)Certificate/MyHome.html',
        'Mod.WorldShare.Certificate.MyHome'
    )

    if params and type(params) == 'table' and params._page then
        params._page.Success = function() self:ShowSuccessPage() end
        params._page.certificateCallback = self.certificateCallback
    end
end

function Certificate:ShowSendSmsPage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        700,
        480,
        '(ws)Certificate/SendSms.html',
        'Mod.WorldShare.Certificate.Sms'
    )

    if params and type(params) == 'table' and params._page then
        params._page.Confirm = function() self:ShowSuccessPage() end
        params._page.certificateCallback = self.certificateCallback
    end
end

function Certificate:ShowSuccessPage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        700,
        480,
        '(ws)Certificate/Success.html',
        'Mod.WorldShare.Certificate.Success'
    )

    if params and type(params) == 'table' and params._page then
        params._page.Confirm = self.certificateCallback
    end
end
