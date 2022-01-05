--[[
Title: Main Login
Author: big  
CreateDate: 2019.12.25
ModifyDate: 2022.1.5
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
MainLogin:ShowUpdatePassword()
------------------------------------------------------------
]]
-- libs
local GameMainLogin = commonlib.gettable('MyCompany.Aries.Game.MainLogin')
local Desktop = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop')
local PlayerAssetFile = commonlib.gettable('MyCompany.Aries.Game.EntityManager.PlayerAssetFile')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")

-- bottles
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local RedSummerCampMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua')

local OfflineAccountManager = commonlib.gettable('Mod.WorldShare.cellar.OfflineAccountManager')

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

local MainLogin = NPL.export()

-- for register
MainLogin.m_mode = 'account'
MainLogin.account = ''
MainLogin.password = ''
MainLogin.phonenumber = ''
MainLogin.phonepassword = ''
MainLogin.phonecaptcha = ''
MainLogin.bindphone = nil

function MainLogin:GetLoginBackground()
    return 'Texture/Aries/Creator/Paracraft/WorldShare/dengluye_1280x720_32bits.png'
end

function MainLogin:Init()
    if System.options.mc == true then
        GameMainLogin:next_step({ IsLoginModeSelected = false })
    end
end

function MainLogin:Show()
    local platform = System.os.GetPlatform()
    local isTouchDevice = ParaEngine.GetAppCommandLineByParam('IsTouchDevice', nil);

    if platform == 'android' or
       platform == 'ios' or
       (isTouchDevice and isTouchDevice =='true') then
        self:ShowAndroid()
        return
    end

    local localVersion = ParaEngine.GetAppCommandLineByParam('localVersion', nil)

    if localVersion == 'SCHOOL' then
        if KeepworkServiceSession:GetUserWhere() == 'LOCAL' then
            local token = Mod.WorldShare.Store:Get('user/token')

            if token then
                KeepworkServiceSession:LoginWithToken(token, function(data, err)
                    data.token = token

                    KeepworkServiceSession:LoginResponse(data, err, function(bSucceed)
                        if bSucceed then
                            SessionsData:SetUserLocation('LOCAL', Mod.WorldShare.Store:Get('user/username'))
                            Create:Show()
                        end
                    end)

                end)
            else
                Create:Show()
            end

            return
        end

        self:Show2()
    else
        self:Show3()
    end
end

function MainLogin:ShowAndroid()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginAndroid.html',
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -1,
        allowDrag = false,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
        bToggleShowHide = false
    })

    self:ShowAndroidLogin()
end

function MainLogin:Show1()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLogin.html', 
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -1,
        allowDrag = false,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
    })

    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return false
    end

    self:ShowExtra()
    self:ShowLogin()
end

function MainLogin:Show2()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLogin.html', 
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -1,
        allowDrag = false,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
    })

    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return false
    end

    self:ShowExtra()
    self:SelectMode()
end

function MainLogin:Show3()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLogin.html', 
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -1,
        allowDrag = false,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
    })

    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return false
    end

    self:ShowExtra()

    -- tricky: Delay show login because in this step some UI library may be not loaded.
    Mod.WorldShare.Utils.SetTimeOut(function()
        self:ShowLogin1()
    end, 0)
end

function MainLogin:ShowLogin()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLogin.html',
        'Mod.WorldShare.cellar.MainLogin.Login',
        0,
        0,
        '_fi',
        false,
        -1
    )

    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if not MainLoginLoginPage then
        return
    end

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo then
        MainLoginLoginPage:SetUIValue('account', PWDInfo.account or '')

        if PWDInfo.rememberMe and PWDInfo.password then
            MainLoginLoginPage:SetUIValue('password_show', PWDInfo.password or '')
            MainLoginLoginPage:SetUIValue('password_hide', PWDInfo.password or '')
            MainLoginLoginPage:SetUIValue('password', PWDInfo.account or '')
            MainLoginLoginPage:SetUIValue('remember_username', PWDInfo.account or '')
            MainLoginLoginPage:SetUIValue('remember_password_name', true)
            MainLoginLoginPage:FindControl('remember_mode').visible = true
            MainLoginLoginPage:FindControl('phone_mode').visible = false
            MainLoginLoginPage:FindControl('account_mode').visible = false
            MainLoginLoginPage:FindControl('title_login').visible = false
            MainLoginLoginPage:FindControl('title_username').visible = true
            MainLoginLoginPage:FindControl('remember_login_button'):SetDefault(true)
            MainLoginLoginPage:SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
        else
            MainLoginLoginPage:FindControl('login_button'):SetDefault(true)
        end
    end
end

function MainLogin:ShowLogin1()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLogin1.html',
        'Mod.WorldShare.cellar.MainLogin.Login',
        0,
        0,
        '_fi',
        false,
        -1,
        nil,
        false
    )

    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if not MainLoginLoginPage then
        return
    end

    if KeepworkServiceSession:IsSignedIn() then
        MainLoginLoginPage:FindControl('phone_mode').visible = false
        MainLoginLoginPage:FindControl('account_mode').visible = false
        MainLoginLoginPage:FindControl('auto_login_mode').visible = true
        MainLoginLoginPage:FindControl('change_button').visible = true
        MainLoginLoginPage:FindControl('update_password_button').visible = true
        MainLoginLoginPage:SetUIValue('auto_username', Mod.WorldShare.Store:Get('user/username') or '')

        MainLoginLoginPage:FindControl('title_login').visible = false
        MainLoginLoginPage:FindControl('title_username').visible = true
    else
        local PWDInfo = KeepworkServiceSession:LoadSigninInfo()
    
        if PWDInfo then
            MainLoginLoginPage:SetUIValue('account', PWDInfo.account or '')
            if PWDInfo.rememberMe then
                local password = PWDInfo.password or ''
                MainLoginLoginPage:SetUIValue('password_show', password)
                MainLoginLoginPage:SetUIValue('password_hide', password)
                MainLoginLoginPage:SetUIValue('password', password)
                MainLoginLoginPage:SetUIValue('account', PWDInfo.account or '')
            end
            if PWDInfo.autoLogin then
                MainLogin:LoginWithToken(PWDInfo.token, function(bSsucceed, reason, message)
                    if bSsucceed then
                        MainLoginLoginPage:SetUIValue('auto_login_name', true)
                        MainLoginLoginPage:SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
    
                        MainLoginLoginPage:FindControl('phone_mode').visible = false
                        MainLoginLoginPage:FindControl('account_mode').visible = false
                        MainLoginLoginPage:FindControl('auto_login_mode').visible = true
                        MainLoginLoginPage:FindControl('change_button').visible = true
                        MainLoginLoginPage:FindControl('update_password_button').visible = true
                        MainLoginLoginPage:SetUIValue('auto_username', PWDInfo.account or '')
    
                        MainLoginLoginPage:FindControl('title_login').visible = false
                        MainLoginLoginPage:FindControl('title_username').visible = true
                    end
                end)
            end
        end
    end
end



function MainLogin:ShowAndroidLogin()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginAndroidLogin.html',
        'Mod.WorldShare.cellar.MainLogin.MainAndroidLogin',
        0,
        0,
        '_fi',
        false,
        -1,
        nil,
        false
    )
end

function MainLogin:ShowAndroidRegister()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginAndroidRegister.html',
        'Mod.WorldShare.cellar.MainLogin.MainAndroidRegister',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowAndroidSetUser()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginAndroidSetUser.html',
        'Mod.WorldShare.cellar.MainLogin.MainAndroidSetUser',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowLoginNew()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLoginNew.html',
        'Mod.WorldShare.cellar.MainLogin.LoginNew',
        0,
        0,
        '_fi',
        false,
        -1
    )

    local MainLoginLoginNewPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginNew')

    if not MainLoginLoginNewPage then
        return
    end

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo then
        MainLoginLoginNewPage:SetUIValue('account', PWDInfo.account or '')
        self.account = PWDInfo.account
    end
end

function MainLogin:ShowLoginAtSchool(mode)
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLoginAtSchool.html',
        'Mod.WorldShare.cellar.MainLogin.LoginAtSchool',
        0,
        0,
        '_fi',
        false,
        -1
    )

    if params then
        params._page.mode = mode
    end

    local MainLoginLoginAtSchoolPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginAtSchool')

    if not MainLoginLoginAtSchoolPage then
        return
    end

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo then
        MainLoginLoginAtSchoolPage:SetUIValue('account', PWDInfo.account or '')
        self.account = PWDInfo.account
    end
end

function MainLogin:ShowRegisterNew(mode)
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginRegisterNew.html',
        'Mod.WorldShare.cellar.MainLogin.RegisterNew',
        0,
        0,
        '_fi',
        false,
        1
    )
end

function MainLogin:ShowRegister()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginRegister.html',
        'Mod.WorldShare.cellar.MainLogin.Register',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowUpdatePassword()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginUpdatePassword.html',
        'Mod.WorldShare.cellar.MainLogin.UpdatePassword',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowParent()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginParent.html',
        'Mod.WorldShare.cellar.MainLogin.Parent',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowWhere(callback)
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginWhere.html',
        'Mod.WorldShare.cellar.MainLogin.Where',
        0,
        0,
        '_fi',
        false,
        -1
    )

    params._page.callback = function(where)
        if callback and type(callback) == 'function' then
            callback(where)
        end
    end
end

function MainLogin:SelectMode(callback)
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginSelectMode.html',
        'Mod.WorldShare.cellar.MainLogin.SelectMode',
        0,
        0,
        '_fi',
        false,
        -1
    )

    params._page.callback = function(mode)
        if callback and type(callback) == 'function' then
            callback(mode)
            return
        end

        if mode == 'HOME' then
            self:ShowLoginNew()
        elseif mode == 'SCHOOL' then
            self:ShowLoginAtSchool('SCHOOL')
        elseif mode == 'LOCAL' then
            self:ShowLoginAtSchool('LOCAL')
        end
    end
end

function MainLogin:ShowExtra()
    local width
    local height
    local left
    local top

    if Mod.WorldShare.Utils.IsEnglish() then
        width = 500
        height = 130
        left = 1000
        top = 160
    else
        width = 400
        height = 140
        left = 680
        top = 360
    end

    Mod.WorldShare.Utils.ShowWindow(
        width,
        height,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginExtra.html',
        'Mod.WorldShare.cellar.MainLogin.Extra',
        left,
        top,
        '_rb',
        false,
        0,
        nil,
        false
    )
    
end

function MainLogin:Refresh(times)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if MainLoginPage then
        MainLoginPage:Refresh(times or 0.01)
    end
end

function MainLogin:Close()
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if MainLoginPage then
        MainLoginPage:CloseWindow()
    end

    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if MainLoginLoginPage then
        MainLoginLoginPage:CloseWindow()
    end

    local MainLoginRegisterPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Register')

    if MainLoginRegisterPage then
        MainLoginRegisterPage:CloseWindow()
    end

    local MainLoginParentPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Parent')

    if MainLoginParentPage then
        MainLoginParentPage:CloseWindow()
    end

    local MainLoginExtraPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Extra')

    if MainLoginExtraPage then
        MainLoginExtraPage:CloseWindow()
    end
end

function MainLogin:LoginWithToken(token, callback)
    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候(TOKEN登录)...', 24000, L'链接超时', 450, 120)

    KeepworkServiceSession:LoginWithToken(token, function(response, err)
        if err ~= 200 or not response then
            Mod.WorldShare.MsgBox:Close()

            if response and response.code and response.message then
                if callback and type(callback) == 'function' then
                    callback(false, 'RESPONSE', format(L'*%s(%d)', response.message, response.code))
                end
            else
                if err == 0 then
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE', format(L'*网络异常或超时，请检查网络(%d)', err))
                    end
                else
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE',  format(L'*系统维护中(%d)', err))
                    end
                end
            end

            return
        end

        response.token = token
        response.autoLogin = true
        -- response.rememberMe = true

        KeepworkServiceSession:LoginResponse(response, err, function(bSucceed, message)
            Mod.WorldShare.MsgBox:Close()
            if not bSucceed then
                if callback and type(callback) == 'function' then
                    callback(false, 'RESPONSE', format(L'*%s', message))
                end
                return
            end

            if callback and type(callback) == 'function' then
                callback(true)
            end
        end)
    end)
end

function MainLogin:AndroidRegisterWithPhoneNumber(...)
    KeepworkServiceSession:RegisterWithPhoneAndLogin(...)
end

function MainLogin:AndroidLoginWithPhoneNumber(phoneNumber, captcha, callback)
    if not Validated:Phone(phoneNumber) then
        if callback and type(callback) == 'function' then
            callback(false, 'ACCOUNT', L'*手机号码格式错误')
        end
        return
    end

    if not captcha then
        if callback and type(callback) == 'function' then
            callback(false, 'CAPTCHA', L'*验证码不能为空')
        end
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候(验证码登录)...', 24000, L'链接超时', 450, 120)

    KeepworkServiceSession:LoginWithPhoneNumber(phoneNumber, captcha, function(response, err)
        response.autoLogin = true
        response.rememberMe = true

        KeepworkServiceSession:LoginResponse(response, err, function(bSucceed, message)
            Mod.WorldShare.MsgBox:Close()

            if not bSucceed then
                if callback and type(callback) == 'function' then
                    callback(false, 'RESPONSE', format(L'*%s', message))
                end
                return
            end

            if callback and type(callback) == 'function' then
                callback(bSucceed)
            end
        end)
    end)
end

function MainLogin:AndroidLoginAction(account, password, callback)
    if not Validated:AccountCompatible(account) then
        if callback and type(callback) == 'function' then
            callback(false, 'ACCOUNT', L'*用户名不合法')
        end
        return
    end

    if not Validated:Password(password) then
        if callback and type(callback) == 'function' then
            callback(false, 'PASSWORD', L'*密码不合法')
        end
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 24000, L'链接超时', 300, 120)

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()

                if response and response.code and response.message then
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE', format(L'*%s(%d)', response.message, response.code))
                    end
                else
                    if err == 0 then
                        if callback and type(callback) == 'function' then
                            callback(false, 'RESPONSE', format(L'*网络异常或超时，请检查网络(%d)', err))
                        end
                    else
                        if callback and type(callback) == 'function' then
                            callback(false, 'RESPONSE',  format(L'*系统维护中(%d)', err))
                        end
                    end
                end

                return
            end

            response.autoLogin = true
            response.rememberMe = true

            KeepworkServiceSession:LoginResponse(response, err, function(bSucceed, message)
                Mod.WorldShare.MsgBox:Close()

                if not bSucceed then
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE',   format(L'*%s', message))
                    end
                    return
                end

                if callback and type(callback) == 'function' then
                    callback(true)
                end

                local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

                if AfterLogined and type(AfterLogined) == 'function' then
                    AfterLogined(true)
                    Mod.WorldShare.Store:Remove('user/AfterLogined')
                end
            end)
        end
    )
end

function MainLogin:LoginAction(callback)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if not MainLoginPage then
        return false
    end

    MainLoginPage:FindControl('account_field_error').visible = false
    MainLoginPage:FindControl('password_field_error').visible = false

    local account = MainLoginPage:GetValue('account')
    local password = MainLoginPage:GetValue('password')

    local pwdNode = MainLoginPage:GetNode('remember_password_name')
    local rememberMe = false

    if pwdNode then
        local rememberMe = pwdNode.checked
    end

    local autoLoginNode = MainLoginPage:GetNode('auto_login_name')
    local autoLogin = false

    if autoLoginNode then
        autoLogin = autoLoginNode.checked
    end

    local validated = true

    if not Validated:AccountCompatible(account) then
        MainLoginPage:SetUIValue('account_field_error_msg', L'*账号不合法')
        MainLoginPage:FindControl('account_field_error').visible = true
        validated = false
    end

    if not Validated:Password(password) then
        MainLoginPage:SetUIValue('password_field_error_msg', L'*密码不合法')
        MainLoginPage:FindControl('password_field_error').visible = true
        validated = false
    end

    if not validated then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 24000, L'链接超时', 300, 120)

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()
        if callback and type(callback) == 'function' then
            callback(bSucceed)
        end

        if not bSucceed then
            MainLoginPage:SetUIValue('account_field_error_msg', format(L'*%s', message))
            MainLoginPage:FindControl('account_field_error').visible = true
            return
        end

        local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

        if type(AfterLogined) == 'function' then
            AfterLogined(true)
            Mod.WorldShare.Store:Remove('user/AfterLogined')
        end
    end

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()

                if response and response.code and response.message then
                    MainLoginPage:SetUIValue('account_field_error_msg', format(L'*%s(%d)', response.message, response.code))
                    MainLoginPage:FindControl('account_field_error').visible = true
                    MainLogin:CheckAutoRegister(account, password, callback)
                else
                    if err == 0 then
                        MainLoginPage:SetUIValue('account_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))
                        MainLoginPage:FindControl('account_field_error').visible = true
                    else
                        MainLoginPage:SetUIValue('account_field_error_msg', format(L'*系统维护中(%d)', err))
                        MainLoginPage:FindControl('account_field_error').visible = true
                    end

                    if callback and type(callback) == 'function' then
                        callback(false)
                    end
                end

                return false
            end

            response.autoLogin = autoLogin
            response.rememberMe = rememberMe
            response.password = password

            if string.find(password, "paracraft.cn") == 1 then
                response.rememberMe = true
            end

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function MainLogin:LoginActionNew(callback)
    local MainLoginNewPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginNew')

    if not MainLoginNewPage then
        return false
    end

    MainLoginNewPage:FindControl('account_field_error').visible = false
    MainLoginNewPage:FindControl('password_field_error').visible = false

    local account = MainLoginNewPage:GetValue('account')
    local password = MainLoginNewPage:GetValue('password')

    local validated = true

    if not Validated:AccountCompatible(account) then
        MainLoginNewPage:SetUIValue('account_field_error_msg', L'*账号不合法')
        MainLoginNewPage:FindControl('account_field_error').visible = true
        validated = false
    end

    if not Validated:Password(password) then
        MainLoginNewPage:SetUIValue('password_field_error_msg', L'*密码不合法')
        MainLoginNewPage:FindControl('password_field_error').visible = true
        validated = false
    end

    if not validated then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 24000, L'链接超时', 300, 120)

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()

        if callback and type(callback) == 'function' then
            callback(bSucceed)
        end

        if not bSucceed then
            MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*%s', message))
            MainLoginNewPage:FindControl('account_field_error').visible = true
            return
        end

        local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

        if type(AfterLogined) == 'function' then
            AfterLogined(true)
            Mod.WorldShare.Store:Remove('user/AfterLogined')
        end
    end

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()

                if response and response.code and response.message then
                    MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*%s(%d)', response.message, response.code))
                    MainLoginNewPage:FindControl('account_field_error').visible = true
                else
                    if err == 0 then
                        MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))
                        MainLoginNewPage:FindControl('account_field_error').visible = true
                    else
                        MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*系统维护中(%d)', err))
                        MainLoginNewPage:FindControl('account_field_error').visible = true
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(false)
                end

                return false
            end

            response.autoLogin = autoLogin
            response.rememberMe = rememberMe
            response.password = password

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function MainLogin:LoginAtSchoolAction(callback)
    local MainLoginAtSchoolPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginAtSchool')

    if not MainLoginAtSchoolPage then
        return false
    end

    MainLoginAtSchoolPage:FindControl('account_field_error').visible = false
    MainLoginAtSchoolPage:FindControl('password_field_error').visible = false

    local account = MainLoginAtSchoolPage:GetValue('account')
    local password = MainLoginAtSchoolPage:GetValue('password')

    local validated = true

    if not Validated:AccountCompatible(account) then
        MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', L'*账号不合法')
        MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
        validated = false
    end

    if not Validated:Password(password) then
        MainLoginAtSchoolPage:SetUIValue('password_field_error_msg', L'*密码不合法')
        MainLoginAtSchoolPage:FindControl('password_field_error').visible = true
        validated = false
    end

    if not validated then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 24000, L'链接超时', 300, 120)

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()

        if callback and type(callback) == 'function' then
            callback(bSucceed)
        end

        if not bSucceed then
            MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*%s', message))
            MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
            return
        end

        local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

        if type(AfterLogined) == 'function' then
            AfterLogined(true)
            Mod.WorldShare.Store:Remove('user/AfterLogined')
        end
    end

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()

                if response and response.code and response.message then
                    MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*%s(%d)', response.message, response.code))
                    MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
                else
                    if err == 0 then
                        MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))
                        MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
                    else
                        MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*系统维护中(%d)', err))
                        MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(false, err)
                end

                return false
            end

            response.autoLogin = autoLogin
            response.rememberMe = rememberMe
            response.password = password

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function MainLogin:RegisterWithAccount(callback, autoLogin)
    if not Validated:Account(self.account) then
        return false
    end

    if not Validated:Password(self.password) then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在注册，请稍候...', 10000, L'链接超时', 500, 120)

    KeepworkServiceSession:RegisterWithAccount(self.account, self.password, function(state)
        Mod.WorldShare.MsgBox:Close()

        if not state then
            GameLogic.AddBBS(nil, L'未知错误', 5000, '0 255 0')
            return
        end

        if state.id then
            if state.code then
                if tonumber(state.code) == 429 then
                    _guihelper.MessageBox(L'操作过于频繁，请在一个小时后再尝试。')
                else
                    GameLogic.AddBBS(nil, format('%s%s(%d)', L'错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
                end
                
            else
                -- set default user role
                local filename = self.GetValidAvatarFilename('boy01')
                GameLogic.options:SetMainPlayerAssetName(filename)

                -- register success
            end

            if self.callback and type(self.callback) == 'function' then
                self.callback(true)
            end

            if callback and type(callback) == 'function' then
                callback(true)
            end

            return
        end

        GameLogic.AddBBS(nil, format('%s%s(%d)', L'注册失败，错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
    end, autoLogin)
end

function MainLogin:RegisterWithPhone(callback)
    if not Validated:Phone(self.phonenumber) then
        return false
    end

    if not Validated:Password(self.password) then
        return false
    end

    if not Validated:Account(self.account) then
        return false
    end

    if not self.phonecaptcha or self.phonecaptcha == '' then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在注册，请稍候...', 10000, L'链接超时', 500, 120)

    KeepworkServiceSession:RegisterWithPhone(self.account, self.phonenumber, self.phonecaptcha, self.password, function(state)
        Mod.WorldShare.MsgBox:Close()

        if not state then
            GameLogic.AddBBS(nil, L'未知错误', 5000, '0 255 0')
            return
        end

        if state.id then
            if state.code then
                GameLogic.AddBBS(nil, format('%s%s(%d)', L'错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
            else
                -- set default user role
                local filename = self.GetValidAvatarFilename('boy01')
                GameLogic.options:SetMainPlayerAssetName(filename)

                -- register success
            end

            if self.callback and type(self.callback) == 'function' then
                self.callback(true)
            end

            if callback and type(callback) == 'function' then
                callback(true)
            end

            return
        end

        GameLogic.AddBBS(nil, format('%s%s(%d)', L'注册失败，错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
    end)
end

function MainLogin:Next(isOffline)
    if KeepworkServiceSession:IsSignedIn() then
        System.options.loginmode = 'online'
    else
        if isOffline then
            System.options.loginmode = 'offline'
        else
            System.options.loginmode = 'local'
        end
    end

    if System.options.cmdline_world and System.options.cmdline_world ~= '' then
        self:Close()
        GameMainLogin:CheckLoadWorldFromCmdLine()
        return
    end

    if System.options.loginmode == 'offline' then
        OfflineAccountManager:ShowActivationPage()
    else
        self:Close()
        RedSummerCampMainPage.Show()
    end
end

-- Depreciated
function MainLogin:EnterUserConsole(isOffline)
    self:Next(isOffline)
end

function MainLogin:GetHistoryUsers()
    return SessionsData:GetSessions().allUsers
end

function MainLogin:Exit()
    Desktop.ForceExit()
end

function MainLogin.GetValidAvatarFilename(playerName)
    if playerName then
        PlayerAssetFile:Init()
        return PlayerAssetFile:GetValidAssetByString(playerName)
    end
end

-- 自动注册功能 账号不存在 用户的密码为：paracraft.cn+1位以上的数字 则帮其自动注册
function MainLogin:CheckAutoRegister(account, password, callback)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
    local start_index,end_index = string.find(password, "paracraft.cn")
    local school_id = string.match(password, "paracraft.cn(%d+)")
    if string.find(password, "paracraft.cn") == 1 and school_id then
        if MainLoginPage then
            MainLoginPage:SetUIValue('account_field_error_msg', "")
        end
        
        KeepworkServiceSession:CheckUsernameExist(account, function(bIsExist)
            if not bIsExist then
                -- 查询学校
                KeepworkServiceSchoolAndOrg:SearchSchoolBySchoolId(tonumber(school_id), function(data)
                    if data and data[1] and data[1].id then
                        
                        MainLogin:AutoRegister(account, password, callback, data[1])
                    end
                end)
            else
                _guihelper.MessageBox(string.format("用户名%s已经被注册，请更换用户名，建议使用名字拼音加出生日期，例如： zhangsan2010", account))
            end
        end)
    else
        if callback and type(callback) == 'function' then
            callback(false)
        end
    end
end

function MainLogin:AutoRegister(account, password, login_cb, school_data)
    -- local account = page:GetValue('register_account')
    -- local password = page:GetValue('register_account_password') or ''

    if not Validated:Account(account) then
        _guihelper.MessageBox([[1.账号需要4位以上的字母或字母+数字组合；<br/>
        2.必须以字母开头；<br/>
        <div style="height: 20px;"></div>
        *推荐使用<div style="color: #ff0000;float: lefr;">名字拼音+出生年份，例如：zhangsan2010</div>]]);
        return false
    end


    if not Validated:Password(password) then
        _guihelper.MessageBox(L'*密码不合法')
        return false
    end

    keepwork.tatfook.sensitive_words_check({
        word=account,
    }, function(err, msg, data)
        if err == 200 then
            -- 敏感词判断
            if data and #data > 0 then
                local limit_world = data[1]
                local begain_index, end_index = string.find(account, limit_world)
                local begain_str = string.sub(account, 1, begain_index-1)
                local end_str = string.sub(account, end_index+1, #account)
                
                local limit_name = string.format([[%s<div style="color: #ff0000;float: lefr;">%s</div>%s]], begain_str, limit_world, end_str)
                _guihelper.MessageBox(string.format("您设定的用户名包含敏感字符 %s，请换一个。", limit_name))
                return
            end

            local region_desc = ""
            local region = school_data.region
            if region then
                local state = region.state and region.state.name or ""
                local city = region.city and region.city.name or ""
                local county = region.county and region.county.name or ""
                region_desc = state .. city .. county
            end
            
            local register_str = string.format("%s是新用户， 你是否希望注册并默认加入学校%s：%s%s", account, school_data.id, region_desc, school_data.name)
            
            _guihelper.MessageBox(register_str, function()
                MainLogin.account = account
                MainLogin.password = password
    
                self.callback = nil
                MainLogin:RegisterWithAccount(function()
                    -- page:SetValue('account_result', account)
                    -- page:SetValue('password_result', password)
                    -- set_finish()
                    login_cb(true)

                    MainLogin:UpdatePasswordRemindVisible(true)
                    Mod.WorldShare.MsgBox:Show(L'正在加入学校，请稍候...', 10000, L'链接超时', 500, 120)
                    Mod.WorldShare.Utils.SetTimeOut(function()
                        KeepworkServiceSchoolAndOrg:ChangeSchool(school_data.id, function(bSuccessed)
                            Mod.WorldShare.MsgBox:Close()
                        end) 
                    end, 500)
                end, false)
            end)
        end
    end)
end

function MainLogin:UpdatePasswordRemindVisible(flag)
    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
    local remind = MainLoginLoginPage:FindControl('update_button_remind')
    local password = MainLoginLoginPage:GetValue('password')
    if flag and string.find(password, "paracraft.cn") == 1 then
        remind.visible = true
    else
        remind.visible = false
    end
end
