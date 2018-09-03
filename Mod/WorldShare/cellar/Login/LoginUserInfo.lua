--[[
Title: LoginUserInfo
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
------------------------------------------------------------
]]
local Encoding = commonlib.gettable("commonlib.Encoding")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")

local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local LoginWorldList = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginWorldList.lua")
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local GenerateMdPage = NPL.load("(gl)Mod/WorldShare/cellar/Common/GenerateMdPage.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local LoginUserInfo = NPL.export()

local ONLINE = "https://keepwork.com"
local STAGE = "https://stage.keepwork.com"
local RELEASE = "https://release.keepwork.com"
local LOCAL = "http://localhost:8099"

if (LOG.level == 'debug') then
    LoginUserInfo.serverLists = {
        {value = ONLINE, name = ONLINE, text = L"使用KEEPWORK登录", selected = true},
        {value = STAGE, name = STAGE, text = L"使用STAGE登录"},
        {value = RELEASE, name = RELEASE, text = L"使用RELEASE登录"},
        {value = LOCAL, name = LOCAL, text = L"使用本地服务登录"}
    }
else
    LoginUserInfo.serverLists = {
        {value = ONLINE, name = ONLINE, text = L"使用KEEPWORK登录", selected = true}
    }
end

LoginUserInfo.ignore_auto_login = nil
LoginUserInfo.hasExplicitLogin = nil
LoginUserInfo.username = nil
LoginUserInfo.isVerified = false

local default_avatars = {
    "boy01",
    "girl01",
    "boy02",
    "girl02",
    "boy03",
    "girl03",
    "boy04",
    "default"
}

local cur_index = 1

function loginRequest(url, params, headers, callback)
    local timeout = false

    commonlib.TimerManager.SetTimeout(
        function()
            if (not timeout) then
                timeout = true
                _guihelper.MessageBox(L"链接超时")
                MsgBox:Close()
            end
        end,
        8000
    )

    HttpRequest:GetUrl(
        {
            url = url,
            json = true,
            form = params,
            headers = headers
        },
        function(data, err)
            if (not timeout) then
                if (err == 503) then
                    _guihelper.MessageBox(L"keepwork正在维护中，我们马上回来")
                    MsgBox:Close()

                    timeout = true
                elseif (err == 200) then
                    if (type(callback) == "function") then
                        callback(data, err)
                    end

                    timeout = true
                end
            end
        end,
        503
    )
end

function loginResponse(page, response, err, callback)
    local account = page and page:GetValue("account")
    local password = page and page:GetValue("password")
    local loginServer = page and page:GetValue("loginServer")
    local isRememberPwd = page and page:GetValue("rememberPassword")
    local autoLogin = page and page:GetValue("autoLogin")

    if (type(response) == "table") then
        if (response["data"] ~= nil and response["data"]["userinfo"]["_id"]) then
            if (not response["data"]["userinfo"]["realNameInfo"]) then
                LoginUserInfo.isVerified = false
            else
                LoginUserInfo.isVerified = true
            end

            local token = response["data"]["token"]

            Store:set('user/token', token)

            -- 手机号或其他账号登陆时，重新获取用户名
            account = response.data.userinfo.defaultSiteDataSource.username

            local getDataSourceApi =
                format("%s/api/wiki/models/site_data_source/getDefaultSiteDataSource", LoginUserInfo.site())

            if (token) then
                HttpRequest:GetUrl(
                    {
                        url = getDataSourceApi,
                        json = true,
                        headers = {
                            Authorization = format("Bearer %s", token)
                        },
                        form = {
                            username = account
                        }
                    },
                    function(data, err)
                        if (not data) then
                            _guihelper.MessageBox(L"数据源不存在，请联系管理员")
                            LoginMain.closeMessageInfo()
                            return
                        end

                        local defaultSiteDataSource = data.data

                        -- 如果记住密码则保存密码到redist根目录下
                        if (isRememberPwd) then
                            LoginUserInfo.SaveSigninInfo(
                                {
                                    account = account,
                                    password = password,
                                    loginServer = loginServer,
                                    token = token,
                                    autoLogin = autoLogin
                                }
                            )
                        end

                        local userinfo = response["data"]["userinfo"]
                        local username = userinfo["username"]
                        local userId = userinfo["_id"]

                        Store:set("user/username", userinfo["username"])
                        Store:set("user/userId", userinfo["_id"])
                        Store:set("user/userinfo", userinfo)

                        local userType

                        if (type(userinfo["vipInfo"]) == "table" and userinfo["vipInfo"]["endDate"]) then
                            local endDate = userinfo["vipInfo"]["endDate"]
                            local datePattern = "(%d+)-(%d+)-(%d+)"

                            local year, month, day = endDate:match(datePattern)

                            local endDateTimestamp

                            if (year and month and day) then
                                endDateTimestamp = os.time({year = year, month = month, day = day})
                            end

                            if (not endDateTimestamp or endDateTimestamp < os.time()) then
                                userType = "normal"
                            else
                                userType = "vip"
                            end
                        else
                            userType = "normal"
                        end

                        Store:set("user/userType", userType)

                        for _, value in ipairs(userinfo["dataSource"]) do
                            if (value.type == defaultSiteDataSource.type) then
                                dataSourceSetting = value
                                break
                            end
                        end

                        if (not dataSourceSetting) then
                            _guihelper.MessageBox(L"数据源配置文件不存在")
                            MsgBox:Close()
                            return
                        end

                        local dataSourceInfo = {
                            dataSourceToken = defaultSiteDataSource["dataSourceToken"], -- 数据源Token
                            dataSourceUsername = defaultSiteDataSource["dataSourceUsername"], -- 数据源用户名
                            dataSourceType = defaultSiteDataSource["type"], -- 数据源类型
                            apiBaseUrl = defaultSiteDataSource["apiBaseUrl"] and string.gsub(defaultSiteDataSource['apiBaseUrl'], 'http://', 'https://') or '', -- 数据源api
                            rawBaseUrl = defaultSiteDataSource["rawBaseUrl"] and string.gsub(defaultSiteDataSource['rawBaseUrl'], 'http://', 'https://') or '', -- 数据源raw
                            keepWorkDataSource = defaultSiteDataSource["projectName"], -- keepwork仓名
                            keepWorkDataSourceId = defaultSiteDataSource["projectId"] -- keepwork仓ID
                        }

                        Store:set("user/dataSourceInfo", dataSourceInfo)

                        LoginUserInfo.personPageUrl =
                            format("%s/%s/paracraft/index", LoginUserInfo.site(), username)

                        --判断paracraf站点是否存在，不存在则创建
                        HttpRequest:GetUrl(
                            {
                                url = format("%s/api/wiki/models/website/getDetailInfo", LoginUserInfo.site()),
                                json = true,
                                headers = {Authorization = format("Bearer %s", token)},
                                form = {
                                    username = username,
                                    sitename = "paracraft"
                                }
                            },
                            function(data, err)
                                local site = data["data"]

                                if (not site) then
                                    LoginMain.closeMessageInfo()
                                    _guihelper.MessageBox(L"检查站点失败")
                                    return
                                end

                                if (not site.siteinfo) then
                                    --创建站点
                                    local siteParams = {
                                        categoryId = 1,
                                        categoryName = "作品网站",
                                        desc = "paracraft作品集",
                                        displayName = "paracraft",--LoginUserInfo.username,
                                        domain = "paracraft",
                                        logoUrl = "/wiki/assets/imgs/paracraft.png",
                                        name = "paracraft",
                                        styleId = 1,
                                        styleName = "WIKI样式",
                                        templateId = 1,
                                        templateName = "WIKI模板",
                                        userId = LoginUserInfo.userId,
                                        username = LoginUserInfo.username
                                    }

                                    HttpRequest:GetUrl(
                                        {
                                            url = format("%s/api/wiki/models/website/new", LoginUserInfo.site()),
                                            json = true,
                                            headers = {Authorization = format("Bearer %s", LoginUserInfo.token)},
                                            form = siteParams
                                        },
                                        function(data, err)
                                        end
                                    )
                                end

                                MsgBox:Close()
                                LoginWorldList.RefreshCurrentServerList()

                                LoginMain.closeLoginModalImp()

                                if (type(callback) == "function") then
                                    callback()
                                end

                                -- GenerateMdPage:genIndexMD()
                            end
                        )
                    end
                )
            end
        else
            MsgBox:Close()
            _guihelper.MessageBox(L"用户名或者密码错误")
        end
    else
        MsgBox:Close()
        _guihelper.MessageBox(L"服务器连接失败")
    end
end

function LoginUserInfo.site()
    local site = Store:get("user/site")

    if not site then
        return ONLINE
    else
        return site
    end
end

function LoginUserInfo.PWDValidation()
    local info = LoginUserInfo.LoadSigninInfo()
    local isDataCorrect = false

    --check site data
    if (info and info.loginServer) then
        for key, item in ipairs(LoginUserInfo.serverLists) do
            if (item.value == info.loginServer) then
                isDataCorrect = true
            end
        end
    end

    if (not isDataCorrect) then
        ParaIO.DeleteFile(LoginUserInfo.GetPasswordFile())
    end
end

function LoginUserInfo.IsSignedIn()
    local token = Store:get("user/token")

    return token ~= nil
end

function LoginUserInfo.CheckoutVerified()
    if (LoginUserInfo.IsSignedIn() and not LoginUserInfo.isVerified) then
        _guihelper.MessageBox(
            L"您需要到keepwork官网进行实名认证，认证成功后需重启paracraft即可正常操作，是否现在认证？",
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    ParaGlobal.ShellExecute("open", format("%s/wiki/user_center", LoginUserInfo.site), "", "", 1)
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )

        return false
    else
        return true
    end
end

function LoginUserInfo.GetValidAvatarFilename(playerName)
    if (playerName) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua")
        local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
        PlayerAssetFile:Init()
        return PlayerAssetFile:GetValidAssetByString(playerName)
    end
end

function LoginUserInfo.LoginAction(page, callback)
    local account = page:GetValue("account")
    local password = page:GetValue("password")

    page:SetNodeValue("account", account)
    page:SetNodeValue("password", password)

    if (account == nil or account == "") then
        _guihelper.MessageBox(L"账号不能为空")
        return
    end

    if (password == nil or password == "") then
        _guihelper.MessageBox(L"密码不能为空")
        return
    end

    MsgBox:Show(L"正在登陆，请稍后...")

    LoginUserInfo.LoginActionApi(
        account,
        password,
        function(response, err)
            loginResponse(page, response, err, callback)
        end
    )
end

function LoginUserInfo.LoginActionModal()
    local LoginModalPage = Store:get('page/LoginModal')

    LoginUserInfo.LoginAction(
        LoginModalPage,
        function()
            if (type(LoginMain.modalCall) == "function") then
                LoginMain.modalCall()
            end

            LoginMain.modalCall = nil
        end
    )
end

function LoginUserInfo.LoginActionMain()
    LoginMain.LoginAction(LoginMain.LoginPage)
end

function LoginUserInfo.IsMCVersion()
    if (System.options.mc) then
        return true
    else
        return false
    end
end

function LoginUserInfo.ChangeName()
    InternetLoadWorld.changedName = true
    LoginMain.refreshPage()
end

function LoginUserInfo.CancelChangeName()
    InternetLoadWorld.changedName = false
    LoginMain.refreshPage()
end

function LoginUserInfo.SaveName()
    InternetLoadWorld.ChangeNickName()
    --changedName = false;
    --Page:Refresh(0.1);
end

function LoginUserInfo.ChangeQQ()
    InternetLoadWorld.changedQQ = true
    LoginMain.refreshPage()
end

function LoginUserInfo.SaveQQ()
    InternetLoadWorld.changedQQ = false
    LoginMain.refreshPage()
end

function LoginUserInfo.GetUserNickName()
    return System.User.NickName or L"匿名"
end

function LoginUserInfo.GetPasswordFile()
    local  writeAblePath = ParaIO.GetWritablePath()

    if (not writeAblePath) then
        return false
    end

    return format("%sPWD", writeAblePath)
end

-- @return nil if not found or {account, password, loginServer, autoLogin}
function LoginUserInfo.LoadSigninInfo()
    local file = ParaIO.open(LoginUserInfo.GetPasswordFile(), "r")
    local fileContent = ""

    if (file:IsValid()) then
        fileContent = file:GetText(0, -1)
        file:close()

        local PWD = {}
        for value in string.gmatch(fileContent, "[^|]+") do
            PWD[#PWD + 1] = value
        end

        local info = {}
        if (PWD[1]) then
            info.account = PWD[1]
        end
        if (PWD[2]) then
            info.password = Encoding.PasswordDecodeWithMac(PWD[2])
        end
        info.loginServer = PWD[3]
        if (PWD[4]) then
            info.token = Encoding.PasswordDecodeWithMac(PWD[4])
        end
        info.autoLogin = (not PWD[5] or PWD[5] == "true")
        return info
    end
end

-- @param info: if nil, we will delete the login info.
function LoginUserInfo.SaveSigninInfo(info)
    if (not info) then
        ParaIO.DeleteFile(LoginUserInfo.GetPasswordFile())
    else
        local newStr =
            format(
            "%s|%s|%s|%s|%s",
            info.account or "",
            Encoding.PasswordEncodeWithMac(info.password or ""),
            (info.loginServer or ""),
            Encoding.PasswordEncodeWithMac(info.token or ""),
            (info.autoLogin and "true" or "false")
        )

        local file = ParaIO.open(LoginUserInfo.GetPasswordFile(), "w")
        if (file) then
            LOG.std(nil, "info", "LoginMain", "save signin info to %s", LoginUserInfo.GetPasswordFile())
            file:write(newStr, #newStr)
            file:close()
        else
            LOG.std(nil, "error", "LoginMain", "failed to write file to %s", LoginUserInfo.GetPasswordFile())
        end
    end
end

function LoginUserInfo.checkDoAutoSignin(callback)
    local info = LoginUserInfo.LoadSigninInfo()

    if (not info or not info.autoLogin or not info.account or not info.password) then
        return false
    end

    MsgBox:Show(L"正在登陆，请稍后...")

    LoginUserInfo.LoginActionApi(
        info.account,
        info.password,
        function(response, err)
            loginResponse(nil, response, err, callback)
        end
    )

    return true
end

function LoginUserInfo.getRememberPassword()
    local info = LoginUserInfo.LoadSigninInfo()
    local LoginModalPage = Store:get('page/LoginModal')
   
    if (not LoginModalPage) then
        return false;
    end

    if (info) then
        if (info.account) then
            LoginModalPage:SetValue("account", info.account)
        end

        if (info.password) then
            LoginModalPage:SetValue("password", info.password)
        end

        LoginModalPage:SetValue("loginServer", info.loginServer)
        LoginModalPage:SetValue("rememberPassword", true)

        LoginModalPage:SetValue("autoLogin", info.autoLogin == true)
    else
        LoginModalPage:SetValue("rememberPassword", false)
        LoginModalPage:SetValue("autoLogin", false)
    end
end

function LoginUserInfo.setSite()
    if (not LoginMain.ModalPage) then
        return false
    end

    local loginServer = LoginMain.ModalPage:GetValue("loginServer")
    Store:set("user/site", loginServer)

    local node = LoginMain.ModalPage:GetNode("register")

    if (node) then
        node:SetAttribute("href", format("%s/wiki/join", loginServer))
    end

    LoginMain.refreshModalPage()
end

function LoginUserInfo.OnClickLogin()
    LoginUserInfo.ignore_auto_login = true

    LoginMain.ShowLoginModalImp(
        function()
            if (page) then
                page:Refresh(0.01)
            end
        end
    )
end

function LoginUserInfo.setRememberAuto()
    local function setRememberAuto(page)
        local account = page:GetValue("account")
        local password = page:GetValue("password")
        local loginServer = page:GetValue("loginServer")

        local auto = page:GetValue("autoLogin")

        if (auto) then
            page:GetNode("autoLogin"):SetAttribute("checked", "checked")
            page:GetNode("rememberPassword"):SetAttribute("checked", "checked")
            page:SetNodeValue("account", account)
            page:SetNodeValue("password", password)

            page:Refresh(0.01)
        else
            local info = LoginUserInfo.LoadSigninInfo()
            if (info) then
                info.autoLogin = false
                LoginUserInfo.SaveSigninInfo(info)
            end
        end
    end

    if (LoginMain.LoginPage and LoginMain.hasExplicitLogin) then
        setRememberAuto(LoginMain.LoginPage)
    end

    if (LoginMain.ModalPage) then
        setRememberAuto(LoginMain.ModalPage)
    end
end

function LoginUserInfo.setAutoRemember()
    local function setAutoRemember(page)
        local account = page:GetValue("account")
        local password = page:GetValue("password")
        local loginServer = page:GetValue("loginServer")

        local remember = page:GetValue("rememberPassword")

        if (not remember) then
            page:GetNode("rememberPassword"):SetAttribute("checked", nil)
            page:GetNode("autoLogin"):SetAttribute("checked", nil)
            page:SetNodeValue("account", account)
            page:SetNodeValue("password", password)

            page:Refresh(0.01)

            LoginUserInfo.SaveSigninInfo(nil)
        end
    end

    if (LoginMain.LoginPage and LoginMain.hasExplicitLogin) then
        setAutoRemember(LoginMain.LoginPage)
    end

    if (LoginMain.ModalPage) then
        setAutoRemember(LoginMain.ModalPage)
    end
end

function LoginUserInfo.autoLoginAction(type)
    if (LoginUserInfo.ignore_auto_login) then
        return
    end

    local function autoLoginAction(page)
        if (not LoginUserInfo.IsSignedIn()) then
            local autoLogin = page:GetValue("autoLogin")

            if (autoLogin) then
                if (type == "main") then
                    LoginUserInfo.LoginActionMain()
                elseif (type == "modal") then
                    LoginUserInfo.LoginActionModal()
                end
            end
        end
    end

    if (LoginMain.LoginPage and LoginMain.hasExplicitLogin) then
        autoLoginAction(LoginMain.LoginPage)
    end

    if (LoginMain.ModalPage) then
        autoLoginAction(LoginMain.ModalPage)
    end
end

function LoginUserInfo.LoginActionApi(account, password, callback)
    local url = format("%s/api/wiki/models/user/login", LoginUserInfo.site())

    local params = {
        username = account,
        password = password
    }

    local headers = {}

    loginRequest(url, params, headers, callback)
end

function LoginUserInfo.LoginWithTokenApi(callback)
    local cmdline = ParaEngine.GetAppCommandLine()
    local urlProtocol = string.match(cmdline or "", "paracraft://(.*)$")
    urlProtocol = string.gsub(urlProtocol or "", "%%22", '"')

    local usertoken = urlProtocol:match('usertoken="([%S]+)"')

    if (type(usertoken) == "string" and #usertoken > 0) then
        LoginMain.showMessageInfo(L"正在登陆，请稍后...")

        local url = format("%s/api/wiki/models/user/getProfile", LoginUserInfo.site())

        local params = {}
        local headers = {
            Authorization = "Bearer " .. usertoken
        }

        loginRequest(
            url,
            params,
            headers,
            function(response)
                if (response and response.data) then
                    local params = {
                        data = {
                            token = usertoken,
                            userinfo = response.data
                        }
                    }

                    loginResponse(nil, params, err, callback)
                end
            end
        )

        return true
    else
        return false
    end
end

--cycle through
-- @param btnName: if nil, we will load the default one if scene is not started.
function LoginUserInfo.OnChangeAvatar(btnName)
    local LoginMainPage = Store:get('page/LoginMain')

    if (not btnName) then
        local filename = GameLogic.options:GetMainPlayerAssetName()
        if (not GameLogic.IsStarted) then
            GameLogic.options:SetMainPlayerAssetName()
            filename = GameLogic.options:GetMainPlayerAssetName()
            if (not filename) then
                filename = LoginUserInfo.GetValidAvatarFilename(default_avatars[cur_index])
                GameLogic.options:SetMainPlayerAssetName(filename)
            end
        end
        if (filename and LoginMainPage) then
            LoginMainPage:CallMethod("MyPlayer", "SetAssetFile", filename)
        end
        return
    end

    if (btnName == "pre") then
        cur_index = cur_index - 1
    else
        cur_index = cur_index + 1
    end
    cur_index = ((cur_index - 1) % (#default_avatars)) + 1
    local playerName = default_avatars[cur_index]

    if (playerName and LoginMainPage) then
        local filename = LoginUserInfo.GetValidAvatarFilename(playerName)
        if (filename) then
            if (GameLogic.RunCommand) then
                GameLogic.RunCommand("/avatar " .. playerName)
            end
            GameLogic.options:SetMainPlayerAssetName(filename)
            LoginMainPage:CallMethod("MyPlayer", "SetAssetFile", playerName)
        end
    end
end

function LoginUserInfo.LookPlayerInform()
    local cur_page = InternetLoadWorld.GetCurrentServerPage()
    local nid = cur_page.player_nid

    if (nid) then
        Map3DSystem.App.Commands.Call(Map3DSystem.options.ViewProfileCommand, nid)
    end
end

function LoginUserInfo.logout()
    if (LoginUserInfo.IsSignedIn()) then
        Store:remove('user/token')
        LoginWorldList.RefreshCurrentServerList()
    end
end