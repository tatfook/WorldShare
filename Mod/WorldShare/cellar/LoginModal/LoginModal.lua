--[[
Title: login modal
Author(s):  big
Date: 2018.11.05
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
LoginModal:Init(function(bSucceed) end)
LoginModal:CheckSignedIn("desc", function(bSucceed) end)
------------------------------------------------------------
]]

local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

-- utils
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

-- UI
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local RegisterModal = NPL.load("(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua")

-- database
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")

local LoginModal = NPL.export()

-- @param callback: called after successfully signed in. 
function LoginModal:Init(callback)
    Mod.WorldShare.Store:Remove('user/AfterLogined')

    if type(callback) == "function" then
        Mod.WorldShare.Store:Set('user/AfterLogined', function(bIsSucceed)
            -- OnKeepWorkLogin
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogin", bIsSucceed)
            return callback(bIsSucceed)
        end)
    else
        Mod.WorldShare.Store:Set('user/AfterLogined', function(bIsSucceed)
            -- OnKeepWorkLogin
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogin", bIsSucceed)
        end)
    end
    self:ShowPage()
end

-- @param desc: login desc
-- @param callback: after login function
function LoginModal:CheckSignedIn(desc, callback)
    if KeepworkServiceSession:IsSignedIn() then
        if type(callback) == "function" then
            callback(true)
        end

        return true
    else
        Mod.WorldShare.Store:Set("user/loginText", desc)
        self:Init(callback)

        return false
    end
end

function LoginModal:ShowPage()
    local RegisterModalPage = Mod.WorldShare.Store:Get("page/RegisterModal")

    if RegisterModalPage then
        RegisterModalPage:CloseWindow()
    end

    if KeepworkServiceSession:GetCurrentUserToken() then
        return false
    end

    local params = Mod.WorldShare.Utils.ShowWindow(320, 470, "Mod/WorldShare/cellar/LoginModal/LoginModal.html", "LoginModal", nil, nil, nil, nil, 5)

    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if not LoginModalPage then
        return false
    end

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo then
        LoginModalPage:SetValue('autoLogin', PWDInfo.autoLogin or false)
        LoginModalPage:SetValue('rememberMe', PWDInfo.rememberMe or false)
        LoginModalPage:SetValue('password', PWDInfo.password or '')
        LoginModalPage:SetValue('showaccount', PWDInfo.account or '')

        self.account = PWDInfo.account
    end

    self:Refresh(0.01)
end

function LoginModal:ClosePage()
    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if(not LoginModalPage) then
        return false
    end

    self.account = nil
    Mod.WorldShare.Store:Remove("user/loginText")

    LoginModalPage:CloseWindow()
end

function LoginModal:Refresh(times)
    local LoginModalPage = Mod.WorldShare.Store:Get('page/LoginModal')

    if LoginModalPage then
        LoginModalPage:Refresh(times or 0.01)
    end
end

function LoginModal:Close(params)
    local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')
    local callback

    if type(AfterLogined) == 'function' then
        callback = AfterLogined(params or false)
        Mod.WorldShare.Store:Remove('user/AfterLogined')
    end

    self:ClosePage()

    return callback
end

function LoginModal:LoginAction()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if not LoginModalPage then
        return false
    end

    local account = LoginModalPage:GetValue("account")
    local password = LoginModalPage:GetValue("password")
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

    Mod.WorldShare.MsgBox:Show(L"正在登录，请稍后...", 32000, L"链接超时", 300, 120, 6)

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()

        if not bSucceed then
            GameLogic.AddBBS(nil, format(L"登录失败了, 错误信息：%s", message), 5000, "255 0 0")
            return
        end

        self:ClosePage()

        if not Mod.WorldShare.Store:Get('user/isBind') then
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

function LoginModal:SetAutoLogin()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if not LoginModalPage then
        return false
    end

    local autoLogin = LoginModalPage:GetValue("autoLogin")
    local rememberMe = LoginModalPage:GetValue("rememberMe")
    local password = LoginModalPage:GetValue("password")
    local account = LoginModalPage:GetValue("showaccount")
    
    if autoLogin then
        LoginModalPage:SetValue("rememberMe", true)
    else
        LoginModalPage:SetValue("rememberMe", rememberMe)
    end
    
    LoginModalPage:SetValue("autoLogin", autoLogin)
    LoginModalPage:SetValue("password", password)
    LoginModalPage:SetValue("account", account)
    LoginModalPage:SetValue("showaccount", account)
    self.account = string.lower(account)

    self:Refresh()
end

function LoginModal:SetRememberMe()
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if not LoginModalPage then
        return false
    end

    local autoLogin = LoginModalPage:GetValue("autoLogin")
    local password = LoginModalPage:GetValue("password")
    local rememberMe = LoginModalPage:GetValue("rememberMe")
    local account = LoginModalPage:GetValue("showaccount")
    
    if rememberMe then
        LoginModalPage:SetValue("autoLogin", autoLogin)
    else
        LoginModalPage:SetValue("autoLogin", false)
    end
    
    LoginModalPage:SetValue("rememberMe", rememberMe)
    LoginModalPage:SetValue("password", password)
    LoginModalPage:SetValue("account", account)
    LoginModalPage:SetValue("showaccount", account)
    self.account = string.lower(account)

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

        LoginModalPage:SetValue("autoLogin", false)
        LoginModalPage:SetValue("rememberMe", false)
        LoginModalPage:SetValue("password", "")
        LoginModalPage:SetValue("showaccount", "")
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

    self.account = session and session.account or ''

    LoginModalPage:SetValue("autoLogin", session.autoLogin)
    LoginModalPage:SetValue("rememberMe", session.rememberMe)
    LoginModalPage:SetValue("password", session.password)
    LoginModalPage:SetValue('showaccount', session.account or '')

    self:Refresh()
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