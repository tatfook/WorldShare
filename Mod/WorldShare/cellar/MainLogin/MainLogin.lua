--[[
Title: Main Login
Author: big  
Date: 2019.12.25
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local MainLogin = NPL.load("(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua")
------------------------------------------------------------
]]
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")
local GameMainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin")

local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepWorkService/Session.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")
local RegisterModal = NPL.load("(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua")

local MainLogin = NPL.export()

function MainLogin:Show()
    Mod.WorldShare.Utils.ShowWindow({
        url = "Mod/WorldShare/cellar/MainLogin/MainLogin.html", 
        name = "MainLogin", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -1,
        allowDrag = false,
        directPosition = true,
            align = "_fi",
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

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo then
        MainLoginPage:SetValue('autoLogin', PWDInfo.autoLogin or false)
        MainLoginPage:SetValue('rememberMe', PWDInfo.rememberMe or false)
        MainLoginPage:SetValue('password', PWDInfo.password or '')

        self.loginServer = PWDInfo.loginServer
        self.account = PWDInfo.account
    end

    self:Refresh()

    if not self.notFirstTimeShown then
        self.notFirstTimeShown = true

        if PWDInfo.autoLogin then
            self:EnterUserConsole()
        end
    end
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
end

function MainLogin:LoginAction()
    local MainLoginPage = Mod.WorldShare.Store:Get("page/MainLogin")

    if not MainLoginPage then
        return false
    end
    
    local loginServer = KeepworkService:GetEnv()
    local account = MainLoginPage:GetValue("account")
    local password = MainLoginPage:GetValue("password")
    local autoLogin = MainLoginPage:GetValue("autoLogin")
    local rememberMe = MainLoginPage:GetValue("rememberMe")

    if not account or account == "" then
        GameLogic.AddBBS(nil, L"账号不能为空", 3000, "255 0 0")
        return false
    end

    if not password or password == "" then
        GameLogic.AddBBS(nil, L"密码不能为空", 3000, "255 0 0")
        return false
    end

    if not loginServer then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"正在登陆，请稍后...", 8000, L"链接超时", 300, 120)

    local function HandleLogined()
        Mod.WorldShare.MsgBox:Close()

        local token = Mod.WorldShare.Store:Get("user/token") or ""

        KeepworkServiceSession:SaveSigninInfo(
            {
                loginServer = loginServer,
                account = account,
                password = password,
                token = token,
                autoLogin = autoLogin,
                rememberMe = rememberMe
            }
        )

        self:EnterUserConsole()

        if not Mod.WorldShare.Store:Get('user/isVerified') then
            RegisterModal:ShowBindingPage()
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
            if err == 503 then
                Mod.WorldShare.MsgBox:Close()
                return false
            end

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function MainLogin:EnterUserConsole()
    ParaWorldLessons.CheckShowOnStartup(function(bBeginLessons)
        if not bBeginLessons then
            System.options.loginmode = "local"

            local MainLoginPage = Mod.WorldShare.Store:Get("page/MainLogin")

            if MainLoginPage then
                MainLoginPage:CloseWindow()
            end

            GameMainLogin:next_step({IsLoginModeSelected = true})
        end
    end)
end

function MainLogin:SetAutoLogin()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if not LoginModalPage then
        return false
    end

    local autoLogin = LoginModalPage:GetValue("autoLogin")
    local rememberMe = LoginModalPage:GetValue("rememberMe")
    local password = LoginModalPage:GetValue("password")
    self.loginServer = KeepworkService:GetEnv()
    self.account = string.lower(LoginModalPage:GetValue("account"))

    if autoLogin then
        LoginModalPage:SetValue("rememberMe", true)
    else
        LoginModalPage:SetValue("rememberMe", rememberMe)
    end
    
    LoginModalPage:SetValue("autoLogin", autoLogin)
    LoginModalPage:SetValue("password", password)

    self:Refresh()
end

function MainLogin:SetRememberMe()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if not LoginModalPage then
        return false
    end

    local loginServer = KeepworkService:GetEnv()
    local password = LoginModalPage:GetValue("password")
    local rememberMe = LoginModalPage:GetValue("rememberMe")
    self.loginServer = KeepworkService:GetEnv()
    self.account = string.lower(LoginModalPage:GetValue("account"))

    if rememberMe then
        LoginModalPage:SetValue("autoLogin", autoLogin)
    else
        LoginModalPage:SetValue("autoLogin", false)
    end

    LoginModalPage:SetValue("rememberMe", rememberMe)
    LoginModalPage:SetValue("password", password)

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

    self.loginServer = session and session.loginServer or 'ONLINE'
    self.account = session and session.account or ''

    MainLoginPage:SetValue("autoLogin", session.autoLogin)
    MainLoginPage:SetValue("rememberMe", session.rememberMe)
    MainLoginPage:SetValue("password", session.password)

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
        self.loginServer = nil

        MainLoginPage:SetValue("autoLogin", false)
        MainLoginPage:SetValue("rememberMe", false)
        MainLoginPage:SetValue("password", "")
    end

    self:Refresh()
end
