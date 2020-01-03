--[[
Title: login modal
Author(s):  big
Date: 2018.11.05
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
LoginModal:ShowPage()
------------------------------------------------------------
]]

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")
local RegisterModal = NPL.load("(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua")

local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")

local LoginModal = NPL.export()

-- @param callbackFunc: called after successfully signed in. 
function LoginModal:Init(callbackFunc)
    Mod.WorldShare.Store:Set('user/AfterLogined', callbackFunc)
    self:ShowPage()
end

function LoginModal:ShowPage()
    if KeepworkServiceSession:GetCurrentUserToken() then
        return false
    end

    local params = Mod.WorldShare.Utils.ShowWindow(320, 470, "Mod/WorldShare/cellar/LoginModal/LoginModal.html", "LoginModal", nil, nil, nil, nil)

    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if not LoginModalPage then
        return false
    end

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo then
        LoginModalPage:SetValue('autoLogin', PWDInfo.autoLogin or false)
        LoginModalPage:SetValue('rememberMe', PWDInfo.rememberMe or false)
        LoginModalPage:SetValue('password', PWDInfo.password or '')

        self.loginServer = PWDInfo.loginServer
        self.account = PWDInfo.account
    end

    self:Refresh(0.01)
end

function LoginModal:ClosePage()
    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if(not LoginModalPage) then
        return false
    end

    self.loginServer = nil
    self.account = nil

    LoginModalPage:CloseWindow()
end

function LoginModal:Refresh(time, callback)
    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if (LoginModalPage) then
        LoginModalPage:Refresh(time or 0.01)
    end
end

function LoginModal:Close(params)
    local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

    if type(AfterLogined) == 'function' then
        AfterLogined(params or false)
        Mod.WorldShare.Store:Remove('user/AfterLogined')
    end

    self:ClosePage()
end

function LoginModal:LoginAction()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if not LoginModalPage then
        return false
    end

    local account = LoginModalPage:GetValue("account")
    local password = LoginModalPage:GetValue("password")
    local loginServer = KeepworkService:GetEnv()
    local autoLogin = LoginModalPage:GetValue("autoLogin")
    local rememberMe = LoginModalPage:GetValue("rememberMe")

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
                account = account,
                password = password,
                loginServer = loginServer,
                token = token,
                autoLogin = autoLogin,
                rememberMe = rememberMe
            }
        )

        self:ClosePage()

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

function LoginModal:GetServerList()
    local serverList = KeepworkService:GetServerList()

    if self.loginServer then
        for key, item in ipairs(serverList) do
            item.selected = nil
            if item.value == self.loginServer then
                item.selected = true
            end
        end
    end

    return serverList
end

function LoginModal:SetAutoLogin()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if not LoginModalPage then
        return false
    end

    local autoLogin = LoginModalPage:GetValue("autoLogin")
    local rememberMe = LoginModalPage:GetValue("rememberMe")
    local password = LoginModalPage:GetValue("password")
    self.loginServer = 'ONLINE' -- LoginModalPage:GetValue("loginServer")
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

function LoginModal:SetRememberMe()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if (not LoginModalPage) then
        return false
    end

    local loginServer = 'ONLINE' -- LoginModalPage:GetValue("loginServer")
    local password = LoginModalPage:GetValue("password")
    local rememberMe = LoginModalPage:GetValue("rememberMe")
    self.loginServer = 'ONLINE' -- LoginModalPage:GetValue("loginServer")
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

function LoginModal:RemoveAccount(username)
    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if not LoginModalPage then
        return false
    end

    SessionsData:RemoveSession(username)

    if self.account == username then
        self.account = nil
        self.loginServer = nil

        LoginModalPage:SetValue("autoLogin", false)
        LoginModalPage:SetValue("rememberMe", false)
        LoginModalPage:SetValue("password", "")
    end

    self:Refresh()
end

function LoginModal:SelectAccount(username)
    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if not LoginModalPage then
        return false
    end

    local session = SessionsData:GetSessionByUsername(username)

    if not session then
        return false
    end

    self.loginServer = session and session.loginServer or 'ONLINE'
    self.account = session and session.account or ''

    LoginModalPage:SetValue("autoLogin", session.autoLogin)
    LoginModalPage:SetValue("rememberMe", session.rememberMe)
    LoginModalPage:SetValue("password", session.password)

    LoginModalPage:Refresh(0.01)
end

function LoginModal:GetHistoryUsers()
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