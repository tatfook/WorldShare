--[[
Title: Certificate
Author(s): big
Date: 2020.11.30
City: Foshan
use the lib:
------------------------------------------------------------
local Certificate = NPL.load('(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua')
------------------------------------------------------------
]]

-- api
local KeepworkParacraftConfigsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkParacraftConfigsApi.lua")

-- libs
local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent")
local TeacherIcon = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherIcon")
local Screen = commonlib.gettable('System.Windows.Screen')

local ServerConfigManager = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/User/ServerConfigManager.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

local Certificate = NPL.export()

Certificate.certificateCallback = nil
Certificate.inited = false

function Certificate:Init(callback)
    local isPay = Mod.WorldShare.Store:Get('user/isPay')

    if System.options.channelId == '430' or isPay ~= 0 then
        self:ShowCertificateNoticePage(callback)
    else
        self:ShowMyHomePage(callback, 'summer')
    end
end

function Certificate:OnWorldLoad()
end

function Certificate:ShowCertificateNoticeSummerVacationPage(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        '(ws)Certificate/CertificateNoticeSummerVacation.html',
        'Mod.WorldShare.CertificateNotice',
        nil,
        nil,
        '_fi',
        false,
        1,
        false,
        nil,
        true
    )

    Screen:Connect('sizeChanged', Certificate, Certificate.OnScreenSizeChange, 'UniqueConnection')

    params._page.callback = callback
    params._page.OnClose = function()
        Screen:Disconnect('sizeChanged', Certificate, Certificate.OnScreenSizeChange)
    end
end

function Certificate:OnScreenSizeChange()
    local page = Mod.WorldShare.Store:Get('page/Mod.WorldShare.CertificateNotice')

    if page then
        page:Rebuild()
    end
end

function Certificate:ShowCertificateNoticePage(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    local params = Mod.WorldShare.Utils.ShowWindow(
        860,
        510,
        '(ws)Certificate/CertificateNotice.html',
        'Mod.WorldShare.CertificateNotice',
        nil,
        nil,
        nil,
        nil,
        1,
        true
    )

    params._page.callback = callback
end

function Certificate:ShowCertificatePage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        800,
        400,
        '(ws)Certificate',
        'Mod.WorldShare.Certificate',
        nil,
        nil,
        nil,
        nil,
        1,
        true
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
        'Mod.WorldShare.Certificate.CertificateType',
        nil,
        nil,
        nil,
        nil,
        1,
        true
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
        'Mod.WorldShare.Certificate.School',
        nil,
        nil,
        nil,
        nil,
        1,
        true
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

function Certificate:ShowMyHomePage(callback, mode)
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/Certificate/MyHome.html?mode=' .. (mode or ''),
        'Mod.WorldShare.Certificate.MyHome',
        nil,
        nil,
        '_fi',
        false,
        1,
        false,
        nil,
        true
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
