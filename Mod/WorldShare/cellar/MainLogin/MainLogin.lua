--[[
Title: Main Login
Author: big  
Date: 2019.12.25
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
------------------------------------------------------------
]]
-- libs
local GameMainLogin = commonlib.gettable('MyCompany.Aries.Game.MainLogin')
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

-- bottles
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

local MainLogin = NPL.export()

-- for register
MainLogin.m_mode = "account"
MainLogin.account = ""
MainLogin.password = ""
MainLogin.phonenumber = ""
MainLogin.phonepassword = ""
MainLogin.phonecaptcha = ""
MainLogin.bindphone = nil

function MainLogin:Init()
    if System.options.mc == true then
        GameMainLogin:next_step({ IsLoginModeSelected = false })
    end
end

function MainLogin:Show()
    local platform = System.os.GetPlatform()

    if platform == 'android' or platform == 'ios' then
        self:ShowAndroid()
        return
    end

    local localVersion = ParaEngine.GetAppCommandLineByParam("localVersion", nil)

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
        self:Show1()
    end
end

function MainLogin:ShowAndroid()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginAndroid.html',
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
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

    self:ShowAndroidLogin()
end

function MainLogin:Show1()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/Theme/MainLogin/MainLogin.html', 
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
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
    self:ShowSelect()
end

function MainLogin:Show2()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/Theme/MainLogin/MainLogin.html', 
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
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

function MainLogin:ShowSelect()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginSelect.html',
        'Mod.WorldShare.cellar.MainLogin.Select',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowLogin()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginLogin.html',
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
        self.account = PWDInfo.account
    end
end

function MainLogin:ShowAndroidLogin()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginAndroidLogin.html',
        'Mod.WorldShare.cellar.MainLogin.MainAndroidLogin',
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
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginAndroidSetUser.html',
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
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginLoginNew.html',
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
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginLoginAtSchool.html',
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
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginRegisterNew.html',
        'Mod.WorldShare.cellar.MainLogin.RegisterNew',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowRegister()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginRegister.html',
        'Mod.WorldShare.cellar.MainLogin.Register',
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
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginParent.html',
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
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginWhere.html',
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
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginSelectMode.html',
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
        height = 130
        left = 800
        top = 160
    end

    Mod.WorldShare.Utils.ShowWindow(
        width,
        height,
        'Mod/WorldShare/cellar/Theme/MainLogin/MainLoginExtra.html',
        'Mod.WorldShare.cellar.MainLogin.Extra',
        left,
        top,
        '_rb',
        false,
        1
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

    local MainLoginSelectPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Select')

    if MainLoginSelectPage then
        MainLoginSelectPage:CloseWindow()
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
                else
                    if err == 0 then
                        MainLoginPage:SetUIValue('account_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))
                        MainLoginPage:FindControl('account_field_error').visible = true
                    else
                        MainLoginPage:SetUIValue('account_field_error_msg', format(L'*系统维护中(%d)', err))
                        MainLoginPage:FindControl('account_field_error').visible = true
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

function MainLogin:RegisterWithAccount(callback)
    if not Validated:Account(self.account) then
        return false
    end

    if not Validated:Password(self.password) then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"正在注册，请稍候...", 10000, L"链接超时", 500, 120)

    KeepworkServiceSession:RegisterWithAccount(self.account, self.password, function(state)
        Mod.WorldShare.MsgBox:Close()

        if not state then
            GameLogic.AddBBS(nil, L"未知错误", 5000, "0 255 0")
            return
        end

        if state.id then
            if state.code then
                GameLogic.AddBBS(nil, format("%s%s(%d)", L"错误信息：", state.message or "", state.code or 0), 5000, "255 0 0")
            else
                -- set default user role
                local filename = UserInfo.GetValidAvatarFilename('boy01')
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

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"注册失败，错误信息：", state.message or "", state.code or 0), 5000, "255 0 0")
    end)
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

    if not self.phonecaptcha or self.phonecaptcha == "" then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"正在注册，请稍候...", 10000, L"链接超时", 500, 120)

    KeepworkServiceSession:RegisterWithPhone(self.account, self.phonenumber, self.phonecaptcha, self.password, function(state)
        Mod.WorldShare.MsgBox:Close()

        if not state then
            GameLogic.AddBBS(nil, L"未知错误", 5000, "0 255 0")
            return
        end

        if state.id then
            if state.code then
                GameLogic.AddBBS(nil, format("%s%s(%d)", L"错误信息：", state.message or "", state.code or 0), 5000, "255 0 0")
            else
                -- set default user role
                local filename = UserInfo.GetValidAvatarFilename('boy01')
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

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"注册失败，错误信息：", state.message or "", state.code or 0), 5000, "255 0 0")
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

    self:Close()

    if System.options.cmdline_world and System.options.cmdline_world ~= '' then
        Mod.WorldShare.MsgBox:Show(L'请稍候...', 12000)
        Mod.WorldShare.Utils.SetTimeOut(function()
            GameMainLogin:CheckLoadWorldFromCmdLine()
        end, 500)
        return
    end

    if System.options.loginmode ~= 'offline' then
        -- close at on world load
        Mod.WorldShare.MsgBox:Show(L'请稍候...', 12000)
    end
    local IsSummerUser = Mod.WorldShare.Utils.IsSummerUser()
    if KeepworkServiceSession:GetUserWhere() == 'HOME' then
        if IsSummerUser then
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('homeWorldId')))
    elseif KeepworkServiceSession:GetUserWhere() == 'SCHOOL' then
        if IsSummerUser then
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('schoolWorldId')))
    else
        GameMainLogin:next_step({IsLoginModeSelected = true})
    end
end

-- Depreciated
function MainLogin:EnterUserConsole(isOffline)
    self:Next(isOffline)
end

function MainLogin:SetAutoLogin()
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return false
    end

    local autoLogin = MainLoginPage:GetValue('autoLogin')
    local rememberMe = MainLoginPage:GetValue('rememberMe')
    local account = MainLoginPage:GetValue('showaccount')
    local password = MainLoginPage:GetValue('password')

    if autoLogin then
        MainLoginPage:SetValue('rememberMe', true)
    else
        MainLoginPage:SetValue('rememberMe', rememberMe)
    end

    MainLoginPage:SetValue('autoLogin', autoLogin)
    MainLoginPage:SetValue('password', password)
    MainLoginPage:SetValue('account', account)
    MainLoginPage:SetValue('showaccount', account)
    self.account = string.lower(account)

    self:Refresh()
end

function MainLogin:SetRememberMe()
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return false
    end

    local autoLogin = MainLoginPage:GetValue('autoLogin')
    local password = MainLoginPage:GetValue('password')
    local rememberMe = MainLoginPage:GetValue('rememberMe')
    local account = MainLoginPage:GetValue('showaccount')

    if rememberMe then
        MainLoginPage:SetValue('autoLogin', autoLogin)
    else
        MainLoginPage:SetValue('autoLogin', false)
    end

    MainLoginPage:SetValue('rememberMe', rememberMe)
    MainLoginPage:SetValue('password', password)
    MainLoginPage:SetValue('account', account)
    MainLoginPage:SetValue('showaccount', account)
    self.account = string.lower(account)

    self:Refresh()
end

function MainLogin:GetHistoryUsers()
    if self.account and #self.account > 0 then
        local allUsers = commonlib.Array:new(SessionsData:GetSessions().allUsers)
        local beExist = false

        for key, item in ipairs(allUsers) do
            item.selected = nil

            if item.value == self.account then
                item.selected = true
                beExist = true
            end
        end

        if not beExist then
            allUsers:push_front({ text = self.account, value = self.account, selected = true })
        end

        return allUsers
    else
        return SessionsData:GetSessions().allUsers
    end
end

function MainLogin:SelectAccount(username)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return false
    end

    local session = SessionsData:GetSessionByUsername(username)

    if not session then
        return false
    end

    self.account = session and session.account or ''

    MainLoginPage:SetValue('autoLogin', session.autoLogin)
    MainLoginPage:SetValue('rememberMe', session.rememberMe)
    MainLoginPage:SetValue('password', session.password)
    MainLoginPage:SetValue('showaccount', session.account or '')

    self:Refresh()
end

function MainLogin:RemoveAccount(username)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return false
    end

    SessionsData:RemoveSession(username)

    if self.account == username then
        self.account = nil

        MainLoginPage:SetValue('autoLogin', false)
        MainLoginPage:SetValue('rememberMe', false)
        MainLoginPage:SetValue('password', '')
        MainLoginPage:SetValue('showaccount', '')
    end

    self:Refresh()
end
