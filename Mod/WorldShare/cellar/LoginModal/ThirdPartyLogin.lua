--[[
Title: third party login
Author(s):  big
Date: 2020.06.01
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local ThirdPartyLogin = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/ThirdPartyLogin.lua")
ThirdPartyLogin:Init(type)
------------------------------------------------------------
]]

-- get table lib
local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer")
local Cef3Manager = commonlib.gettable("Mod.WorldShare.service.Cef3Manager")
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin")

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local NPLServerService = NPL.load("(gl)Mod/WorldShare/service/NPLServerService.lua")

local ThirdPartyLogin = NPL.export()

ThirdPartyLogin.port = 8099

function ThirdPartyLogin:Init(thirdPartyType, callback)
    if System.os.GetPlatform() ~= 'win32' and System.os.GetPlatform() ~= 'mac' then
        _guihelper.MessageBox(L"操作不支持此系统")
        return false
    end

    if self.beShowed then
        if thirdPartyType == self.thirdPartyType then
            return false
        else
            local ThirdPartyLoginPage = Mod.WorldShare.Store:Get('page/ThirdPartyLogin')
            if ThirdPartyLoginPage then
                ThirdPartyLoginPage:CloseWindow()
            end
        end
    end

    self.beShowed = true
    self.curThirdPartyType = thirdPartyType

    local function Handle()
        self.thirdPartyType = thirdPartyType
        self.callback = callback

        if self.needToWait then
            Mod.WorldShare.MsgBox:Show(L"请稍后...", nil, nil, nil, nil, 6)

            Mod.WorldShare.Utils.SetTimeOut(function()
                Mod.WorldShare.MsgBox:Close()

                self.beShowed = false
                self:Init(thirdPartyType, callback)
            end, 1500)
            return false
        end
    
        self.needToWait = true

        if System.os.GetPlatform() == 'win32' then
            NplBrowserPlugin.OnCreatedCallback("thridpartylogin",function()
                local ThirdPartyLoginPage = Mod.WorldShare.Store:Get('page/ThirdPartyLogin')
                if ThirdPartyLoginPage then
                    ThirdPartyLoginPage:Refresh(0)
                end
            end)
        end
    
        local params = Mod.WorldShare.Utils.ShowWindow(400, 450, "Mod/WorldShare/cellar/LoginModal/ThirdPartyLogin.html", "ThirdPartyLogin", nil, nil, nil, nil, 6)

        params._page:CallMethod("thridpartylogin", "SetVisible", true)
        params._page.OnClose = function()
            Mod.WorldShare.Store:Remove('page/ThirdPartyLogin')
            params._page:CallMethod("thridpartylogin", "SetVisible", false)
            Mod.WorldShare.Store:Unsubscribe("user/SetThirdPartyLoginAuthinfo")

            self.beShowed = false

            Mod.WorldShare.Utils.SetTimeOut(function()
                params._page:CallMethod("thridpartylogin", "Reload", "https://keepwork.com/zhanglei/empty/index")
                self.needToWait = false
            end, 1000)
        end
    
        Mod.WorldShare.Store:Subscribe("user/SetThirdPartyLoginAuthinfo", function()
            local authType = Mod.WorldShare.Store:Get("user/authType")
            local authCode = Mod.WorldShare.Store:Get("user/authCode")

            KeepworkServiceSession:CheckOauthUserExisted(authType, authCode, function(bExisted, data)
                params._page:CloseWindow()

                if bExisted then
                    Mod.WorldShare.Store:Set("user/token", data.token)
                    -- login again to enter world
                    local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
                    UserInfo:LoginWithToken(function()
						GameLogic.GetFilters():apply_filters("OnKeepWorkLogin", true);
                        if type(self.callback) == "function" then
                            self.callback()
                        end      
		            end);
                else
                    if data and data.token then
                        Mod.WorldShare.Store:Set("user/authToken", data.token)
                    else
                        Mod.WorldShare.Store:Remove("user/authToken")
                    end

                    Mod.WorldShare.MsgBox:Dialog(
                        "NoThirdPartyAccountNotice",
                        L"检测到该第三方账号还未绑定到账号，请绑定到已有账号或者新建账号进行绑定",
                        {
                            Title = L"补充账号信息",
                            Yes = L"绑定到已有账号",
                            No = L"新建账号并绑定"
                        },
                        function(res)
                            if res and res == _guihelper.DialogResult.Yes then
                                self:ShowCreateOrBindThirdPartyAccountPage("bind")
                            end
    
                            if res and res == _guihelper.DialogResult.No then
                                self:ShowCreateOrBindThirdPartyAccountPage("create")
                            end
                        end,
                        _guihelper.MessageBoxButtons.YesNo,
                        {
                            Yes = {
                                marginLeft = "40px",
                                width = "120px"
                            },
                            No = {
                                width = "120px"
                            }
                        }
                    )
    
                    return false
                end
            end)
        end)
    end


    if System.os.GetPlatform() == "win32" then
        Mod.WorldShare.MsgBox:Show(L"请稍后...", nil, nil, nil, nil, 6)
        NPLServerService:CheckDefaultServerStarted(function(bStarted, siteUrl)
            Mod.WorldShare.MsgBox:Close()
            if not bStarted or not siteUrl then
                return false
            end

            self.port = siteUrl:match("%:(%d+)") or self.port

            if Cef3Manager.bLoaded then
                Handle()
            else
                Mod.WorldShare.MsgBox:Show(L"请稍后...", 30000, nil, nil, nil, 6)
                Cef3Manager:Connect("finishLoadCef3", nil, function()
                    Mod.WorldShare.MsgBox:Close()
                    Handle()
                end, "UniqueConnection")
            end
        end)
    end

    if System.os.GetPlatform() == "mac" then
        Handle()
    end
end

function ThirdPartyLogin:GetUrl()
    local redirect_uri = Mod.WorldShare.Utils.EncodeURIComponent(KeepworkService:GetKeepworkUrl() .. '/p/third-login')
    local sysTag = ''

    if System.os.GetPlatform() == 'win32' then
        sysTag = "WIN32"
    elseif System.os.GetPlatform() == 'mac' then
        sysTag = "MAC"
    end

    if self.thirdPartyType == 'WECHAT' then
        local clientId = KeepworkServiceSession:GetOauthClientId("WECHAT")
        local state = Mod.WorldShare.Utils.EncodeURIComponent("WECHAT|" .. sysTag .. "|" .. self.port .. "|" .. System.Encoding.guid.uuid())

        return
            format(
                "https://open.weixin.qq.com/connect/qrconnect?appid=%s&redirect_uri=%s&response_type=code&scope=snsapi_login&state=%s#wechat_redirect",
                clientId,
                redirect_uri,
                state
            )
    end

    if self.thirdPartyType == "QQ" then
        local clientId = KeepworkServiceSession:GetOauthClientId("QQ")
        local state = Mod.WorldShare.Utils.EncodeURIComponent("QQ|" .. sysTag .. "|" .. self.port .. "|" .. System.Encoding.guid.uuid())

        return 
            format(
                "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=%s&redirect_uri=%s&state=%s",
                clientId,
                redirect_uri,
                state
            )
    end

    return ""
end

function ThirdPartyLogin:ShowCreateOrBindThirdPartyAccountPage(method)
    Mod.WorldShare.Utils.ShowWindow(400, 300, "Mod/WorldShare/cellar/LoginModal/CreateOrBindThirdPartyAccount.html?method=" .. (method or ""), "CreateOrBindThirdPartyAccount")
end

function ThirdPartyLogin:RegisterAndBind(account, password, authToken)
    Mod.WorldShare.MsgBox:Show(L"请稍后...")

    KeepworkServiceSession:RegisterAndBindThirdPartyAccount(account, password, authToken, function(state)
        Mod.WorldShare.MsgBox:Close()

        local CreateOrBindThirdPartyAccountPage = Mod.WorldShare.Store:Get("page/CreateOrBindThirdPartyAccount")

        if CreateOrBindThirdPartyAccountPage then
            CreateOrBindThirdPartyAccountPage:CloseWindow()
        end

        if not state then
            GameLogic.AddBBS(nil, L"未知错误", 5000, "0 255 0")
            return false
        end

        if state.id then
            if state.code then
                GameLogic.AddBBS(nil, format("%s%s(%d)", L"错误信息：", state.message or "", state.code or 0), 5000, "255 0 0")
            else
                -- register success
                -- OnKeepWorkLogin
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogin", true)

                GameLogic.AddBBS(nil, L"注册成功，绑定第三方账号成功", 5000, "0 255 0")

                if type(self.callback) == "function" then
                    self.callback()
                end
            end

            return true
        end

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"注册失败，错误信息：", state.message or "", state.code or 0), 5000, "255 0 0")
    end)
end

function ThirdPartyLogin:LoginAndBind(account, password, authToken)
    Mod.WorldShare.MsgBox:Show(L"请稍后...")

    KeepworkServiceSession:LoginAndBindThirdPartyAccount(account, password, authToken, function(response, err)
        if err ~= 200 or not response then
            Mod.WorldShare.MsgBox:Close()
            if response and response.code and response.message then
                GameLogic.AddBBS(nil, format(L"登录失败了, 错误信息：%s(%d)", response.message, response.code), 5000, "255 0 0")
            else
                GameLogic.AddBBS(nil, format(L"登录失败了, 错误码：%d", err), 5000, "255 0 0")
            end

            return false
        end

        KeepworkServiceSession:LoginResponse(response, err, function()
            Mod.WorldShare.MsgBox:Close()

            local CreateOrBindThirdPartyAccountPage = Mod.WorldShare.Store:Get("page/CreateOrBindThirdPartyAccount")

            if CreateOrBindThirdPartyAccountPage then
                CreateOrBindThirdPartyAccountPage:CloseWindow()
            end

            -- OnKeepWorkLogin
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogin", true)
    
            GameLogic.AddBBS(nil, L"登录成功，绑定第三方账号成功", 5000, "0 255 0")

            if type(self.callback) == "function" then
                self.callback()
            end
        end)
    end)
end