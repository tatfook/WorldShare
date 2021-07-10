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

-- libs
local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent")
local TeacherIcon = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherIcon")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local Certificate = NPL.export()

Certificate.certificateCallback = nil
Certificate.inited = false

function Certificate:OnWorldLoad()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    local isVerified = Mod.WorldShare.Store:Get('user/isVerified')
    local hasJoinedSchool = Mod.WorldShare.Store:Get('user/hasJoinedSchool')

    if not isVerified or not hasJoinedSchool then
        self:ShowCertificateNoticePage()
    end
end

function Certificate:ShowCertificateNoticePage(callback)
    local params = Mod.WorldShare.Utils.ShowWindow(
        860,
        480,
        '(ws)Certificate/CertificateNotice.html',
        'Mod.WorldShare.CertificateNotice'
    )

    params._page.callback = callback
end

function Certificate:Init(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        GameLogic.AddBBS(nil, L"请先登录", 3000, "255 0 0")
        return
    end

    if KeepworkServiceSession:IsRealName() then
        if callback and type(callback) == 'function' then
            callback(true)
        end
        return
    end

    self.certificateCallback = callback

    self:ShowCertificatePage()
end

function Certificate:ShowCertificatePage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        800,
        400,
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
        605,
        410,
        '(ws)Certificate/CertificateType.html',
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
        params._page.Confirm = function(cellphone, realname)
            KeepworkServiceSession:TextingToInviteRealname(cellphone, realname, function(data, err)
                if err ~= 200 then
                    return
                end
                params._page:CloseWindow()
                self:ShowSendSmsPage()
            end)
        end
        params._page.certificateCallback = self.certificateCallback
    end
end

function Certificate:ShowMyHomePage(callback)
    local params = Mod.WorldShare.Utils.ShowWindow(
        800,
        480,
        '(ws)Certificate/MyHome.html',
        'Mod.WorldShare.Certificate.MyHome'
    )

    if params and type(params) == 'table' and params._page then
        params._page.certificateCallback = callback
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
        360,
        '(ws)Certificate/Success.html',
        'Mod.WorldShare.Certificate.Success'
    )

    if params and type(params) == 'table' and params._page then
        params._page.Confirm = self.certificateCallback
    end
end
