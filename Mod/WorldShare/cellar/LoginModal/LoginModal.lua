--[[
Title: login modal
Author(s):  big
Date: 2018.11.05
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginModal/LoginModal.lua")
if(not UserConsole.IsSignedIn()) then
    UserConsole.ShowLoginModal(callbackFunc)
end
------------------------------------------------------------
]]

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local UserConsole = NPL.load("../UserConsole.lua")
local LoginUserInfo = NPL.load("../LoginUserInfo.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")

local LoginModal = NPL.export()

-- @param callbackFunc: called after successfully signed in. 
function LoginModal:Init(callbackFunc)
    Store:Set('user/AfterLogined', callbackFunc)
    self:ShowPage()
end

function LoginModal:ShowPage()
    if (KeepworkService:LoginWithTokenApi()) then
        return true
    end

    local params = Utils:ShowWindow(320, 470, "Mod/WorldShare/cellar/LoginModal/LoginModal.html", "LoginModal", nil, nil, nil, nil, 999)

    params._page.OnClose = function()
        Store:Remove('page/LoginModal')
    end

    local LoginModalPage = Store:Get('page/LoginModal')

    if not LoginModalPage then
        return false
    end

    local PWDInfo = KeepworkService:LoadSigninInfo()

    if (PWDInfo) then
        local rememberMeNode = LoginModalPage:GetNode('rememberPassword')
        local autoLoginNode = LoginModalPage:GetNode('autoLogin')

        rememberMeNode:SetAttribute('checked', 'checked')

        if PWDInfo and PWDInfo.autoLogin then
            autoLoginNode:SetAttribute('checked', 'checked')
        end

        LoginModalPage:SetValue('loginServer', PWDInfo.loginServer or '')
        LoginModalPage:SetValue('account', PWDInfo.account or '')
        LoginModalPage:SetValue('password', PWDInfo.password or '')
    end

    local forgotUrl = format("%s/u/set", KeepworkService:GetKeepworkUrl())
    local registerUrl = format("%s/u/r/register", KeepworkService:GetKeepworkUrl())

    LoginModalPage:GetNode('forgot'):SetAttribute('href', forgotUrl)
    LoginModalPage:GetNode('register'):SetAttribute('href', registerUrl)

    self:Refresh()
end

function LoginModal:SetPage()
    Store:Set('page/LoginModal', document:GetPageCtrl())
end

function LoginModal:ClosePage()
    local LoginModalPage = Store:Get('page/LoginModal')

    if(not LoginModalPage) then
        return false
    end

    LoginModalPage:CloseWindow()
end

function LoginModal:Refresh(time)
    local LoginModalPage = Store:Get('page/LoginModal')

    if (LoginModalPage) then
        LoginModalPage:Refresh(time or 0.01)
    end
end

function LoginModal:LoginAction()
    local LoginModalPage = Store:Get("page/LoginModal")

    if (not LoginModalPage) then
        return false
    end

    local account = LoginModalPage:GetValue("account")
    local password = LoginModalPage:GetValue("password")
    local env = LoginModalPage:GetValue("loginServer")
    local autoLogin = LoginModalPage:GetValue("autoLogin")
    local rememberMe = LoginModalPage:GetValue("rememberPassword")

    local inputLoginInfo = {
        account = account,
        password = password,
        site = env,
        autoLogin = autoLogin,
        rememberMe = rememberme
    }

    Store:Set("user/inputLoginInfo", inputLoginInfo)

    if (not account or account == "") then
        _guihelper.MessageBox(L"账号不能为空")
        return false
    end

    if (not password or password == "") then
        _guihelper.MessageBox(L"密码不能为空")
        return false
    end

    if (not env) then
        _guihelper.MessageBox(L"登陆站点不能为空")
        return false
    end

    Store:Set("user/env", env)

    MsgBox:Show(L"正在登陆，请稍后...")

    local function HandleLogined()
        local token = Store:Get("user/token") or ""

        -- 如果记住密码则保存密码到redist根目录下
        if (rememberMe) then
            KeepworkService:SaveSigninInfo(
                {
                    account = account,
                    password = password,
                    loginServer = env,
                    token = token,
                    autoLogin = autoLogin
                }
            )
        else
            KeepworkService:SaveSigninInfo()
        end

        self:ClosePage()
        WorldList:RefreshCurrentServerList()

        local AfterLogined = Store:Get('user/AfterLogined')

        if type(AfterLogined) == 'function' then
            AfterLogined()
            Store:Remove('user/AfterLogined')
        end

        -- if (type(callback) == "function") then
        --     callback()
        -- end
    end

    KeepworkService:Login(
        account,
        password,
        function(response, err)
            KeepworkService:LoginResponse(response, err, HandleLogined)
        end
    )
end

function LoginModal:GetServerList()
    return KeepworkService:GetServerList()
end

function LoginModal:SetAutoLogin()
    local LoginModalPage = Store:Get("page/LoginModal")

    if (not LoginModalPage) then
        return false
    end

    local autoLogin = LoginModalPage:GetValue("autoLogin")
    local loginServer = LoginModalPage:GetValue("loginServer")
    local account = LoginModalPage:GetValue("account")
    local password = LoginModalPage:GetValue("password")
    local rememberMe = LoginModalPage:GetValue("rememberPassword")

    if (autoLogin) then
        LoginModalPage:SetValue("rememberPassword", true)
        LoginModalPage:SetValue("autoLogin", true)
    else
        LoginModalPage:SetValue("rememberPassword", rememberMe)
        LoginModalPage:SetValue("autoLogin", false)
    end

    LoginModalPage:SetValue("loginServer", loginServer)
    LoginModalPage:SetValue("account", account)
    LoginModalPage:SetValue("password", password)

    self:Refresh()
end