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
        MainLoginPage:SetValue('showaccount', PWDInfo.account or '')
        self.account = PWDInfo.account
    end

    self:Refresh()

    if not self.notFirstTimeShown then
        self.notFirstTimeShown = true

        if System.User.keepworktoken then
            Mod.WorldShare.MsgBox:Show(L"正在登录，请稍后...", 8000, L"链接超时", 300, 120)

            KeepworkServiceSession:LoginWithToken(
                System.User.keepworktoken,
                function(response, err)
                    Mod.WorldShare.MsgBox:Close()

                    if(err == 200 and type(response) == "table" and response.username) then
                        self:EnterUserConsole()
                    else
                        -- token expired
                        System.User.keepworktoken = nil;
                    end
                end
            )

            Mod.WorldShare.Store:Set('user/AfterLogined', function(bIsSucceed)
				-- OnKeepWorkLogin
				GameLogic.GetFilters():apply_filters("OnKeepWorkLogin", bIsSucceed)
			end)

            return
        end

        -- if PWDInfo and PWDInfo.autoLogin then
        --     Mod.WorldShare.Utils.SetTimeOut(function()
        --         self:EnterUserConsole()
        --     end, 100)
        -- end
    end

    Mod.WorldShare.Store:Set('user/AfterLogined', function(bIsSucceed)
        -- OnKeepWorkLogin
        GameLogic.GetFilters():apply_filters("OnKeepWorkLogin", bIsSucceed)
    end)
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


    Mod.WorldShare.MsgBox:Show(L"正在登录，请稍后...", 8000, L"链接超时", 300, 120)

    local function HandleLogined()
        Mod.WorldShare.MsgBox:Close()

        self:EnterUserConsole()

        -- if not Mod.WorldShare.Store:Get('user/isBind') then
        --     RegisterModal:ShowBindingPage()
        -- end

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
                    GameLogic.AddBBS(nil, format(L"登录失败了, 错误信息：%s(%d)", response.message, response.code), 5000, "255 0 0")
                else
                    GameLogic.AddBBS(nil, format(L"登录失败了, 系统维护中, 错误码：%d", err), 5000, "255 0 0")
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

function MainLogin:EnterUserConsole(isOffline)
    ParaWorldLessons.CheckShowOnStartup(function(bBeginLessons)
        if not bBeginLessons then
            System.options.loginmode = "local"

            if isOffline then
                System.options.loginmode = "offline"
            end

            local MainLoginPage = Mod.WorldShare.Store:Get("page/MainLogin")

            if MainLoginPage then
                MainLoginPage:CloseWindow()
            end

            GameMainLogin:next_step({IsLoginModeSelected = true})
        end
    end)
end

function MainLogin:SetAutoLogin()
    local MainLoginPage = Mod.WorldShare.Store:Get("page/MainLogin")

    if not MainLoginPage then
        return false
    end

    local autoLogin = MainLoginPage:GetValue("autoLogin")
    local rememberMe = MainLoginPage:GetValue("rememberMe")
    local account = MainLoginPage:GetValue("showaccount")
    local password = MainLoginPage:GetValue("password")

    if autoLogin then
        MainLoginPage:SetValue("rememberMe", true)
    else
        MainLoginPage:SetValue("rememberMe", rememberMe)
    end

    MainLoginPage:SetValue("autoLogin", autoLogin)
    MainLoginPage:SetValue("password", password)
    MainLoginPage:SetValue("account", account)
    MainLoginPage:SetValue("showaccount", account)
    self.account = string.lower(account)

    self:Refresh()
end

function MainLogin:SetRememberMe()
    local MainLoginPage = Mod.WorldShare.Store:Get("page/MainLogin")

    if not MainLoginPage then
        return false
    end

    local autoLogin = MainLoginPage:GetValue("autoLogin")
    local password = MainLoginPage:GetValue("password")
    local rememberMe = MainLoginPage:GetValue("rememberMe")
    local account = MainLoginPage:GetValue("showaccount")

    if rememberMe then
        MainLoginPage:SetValue("autoLogin", autoLogin)
    else
        MainLoginPage:SetValue("autoLogin", false)
    end

    MainLoginPage:SetValue("rememberMe", rememberMe)
    MainLoginPage:SetValue("password", password)
    MainLoginPage:SetValue("account", account)
    MainLoginPage:SetValue("showaccount", account)
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

    MainLoginPage:SetValue("autoLogin", session.autoLogin)
    MainLoginPage:SetValue("rememberMe", session.rememberMe)
    MainLoginPage:SetValue("password", session.password)
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

        MainLoginPage:SetValue("autoLogin", false)
        MainLoginPage:SetValue("rememberMe", false)
        MainLoginPage:SetValue("password", "")
        MainLoginPage:SetValue("showaccount", "")
    end

    self:Refresh()
end
