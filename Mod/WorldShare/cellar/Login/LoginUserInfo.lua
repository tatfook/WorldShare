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

function loginResponse(response, err, callback)
    if (type(response) ~= "table") then
        MsgBox:Close()
        _guihelper.MessageBox(L"服务器连接失败")
        return false
    end

    if (
        not response["data"] or
        not response["data"]["token"] or
        not response["data"]["userinfo"] or
        not response["data"]["userinfo"]["_id"]
    ) then
        MsgBox:Close()
        _guihelper.MessageBox(L"用户名或者密码错误")
        return false
    end

    local token = response["data"]["token"] or ''
    local userinfo = response["data"]["userinfo"] or {}
    local userId = userinfo["_id"] or 0
    local username = userinfo["username"] or ''

    Store:set('user/token', token)
    Store:set("user/userinfo", userinfo)
    Store:set("user/userId", userId)
    Store:set("user/username", username)

    if (not userinfo["realNameInfo"]) then
        Store:set('user/isVerified', false)
    else
        Store:set('user/isVerified', true)
    end

    -- ensure account is correct when login with phone or email
    local username = userinfo['defaultSiteDataSource'] and userinfo['defaultSiteDataSource']['username'] or ''

    local getDataSourceApi =
        format("%s/api/wiki/models/site_data_source/getDefaultSiteDataSource", LoginUserInfo.site())

    local function handleGetDataSource(response, err)
        if (not response) then
            _guihelper.MessageBox(L"数据源不存在，请联系管理员")
            MsgBox:Close()
            return
        end

        local defaultSiteDataSource = response.data or {}

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

        LoginUserInfo.CreateParacraftSite(callback)
    end

    local params = {
        url = getDataSourceApi,
        json = true,
        headers = {
            Authorization = format("Bearer %s", token)
        },
        form = {
            username = username
        }
    }

    HttpRequest:GetUrl(params, handleGetDataSource)
end

function LoginUserInfo.CreateParacraftSite(callback)
    local username = Store:get('user/username')
    local token = Store:get('user/token')
    local userId = Store:get('user/userId')

    if (not username or not token) then
        return false
    end

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
                MsgBox:Close()
                _guihelper.MessageBox(L"检查站点失败")
                return false
            end

            if (not site.siteinfo) then
                --创建站点
                local siteParams = {
                    categoryId = 1,
                    categoryName = "作品网站",
                    desc = "paracraft作品集",
                    displayName = "paracraft",
                    domain = "paracraft",
                    logoUrl = "/wiki/assets/imgs/paracraft.png",
                    name = "paracraft",
                    styleId = 1,
                    styleName = "WIKI样式",
                    templateId = 1,
                    templateName = "WIKI模板",
                    userId = userId,
                    username = username
                }

                HttpRequest:GetUrl(
                    {
                        url = format("%s/api/wiki/models/website/new", LoginUserInfo.site()),
                        json = true,
                        headers = {Authorization = format("Bearer %s", token)},
                        form = siteParams
                    }
                )
            end

            MsgBox:Close()

            local LoginMainPage = Store:get('page/LoginMain')

            if LoginMainPage then
                LoginWorldList.RefreshCurrentServerList()
            end

            local afterLogined = Store:get('user/afterLogined')

            if type(afterLogined) == 'function' then
                afterLogined()
                Store:remove('user/afterLogined')
            end

            if (type(callback) == "function") then
                callback()
            end
        end
    )
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
    local isVerified = Store:get('user/isVerified')

    if (LoginUserInfo.IsSignedIn() and not isVerified) then
        _guihelper.MessageBox(
            L"您需要到keepwork官网进行实名认证，认证成功后需重启paracraft即可正常操作，是否现在认证？",
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    ParaGlobal.ShellExecute("open", format("%s/wiki/user_center", LoginUserInfo.site()), "", "", 1)
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

function LoginUserInfo.LoginActionModal()
    local LoginModalImp = Store:get('page/LoginModal')

    if (not LoginModalImp) then
        return false
    end

    local account = LoginModalImp:GetValue("account")
    local password = LoginModalImp:GetValue("password")
    local site = LoginModalImp:GetValue("loginServer")
    local autoLogin = LoginModalImp:GetValue("autoLogin")
    local rememberMe = LoginModalImp:GetValue("rememberPassword")

    local inputLoginInfo = {
        account = account,
        password = password,
        site = site,
        autoLogin = autoLogin,
        rememberMe = rememberme
    }

    Store:set('user/inputLoginInfo', inputLoginInfo)

    if (not account or account == '') then
        _guihelper.MessageBox(L"账号不能为空")
        return false
    end

    if (not password or password == '') then
        _guihelper.MessageBox(L"密码不能为空")
        return false
    end

    if (not site) then
        _guihelper.MessageBox(L"登陆站点不能为空")
        return false
    end

    Store:set('user/site', site)

    MsgBox:Show(L"正在登陆，请稍后...")

    local function handleLogined()
        local token = Store:get('user/token') or ''

        -- 如果记住密码则保存密码到redist根目录下
        if (rememberMe) then
            LoginUserInfo.SaveSigninInfo(
                {
                    account = account,
                    password = password,
                    loginServer = site,
                    token = token,
                    autoLogin = autoLogin
                }
            )
        else
            LoginUserInfo.SaveSigninInfo()
        end

        LoginMain.closeLoginModalImp()
    end

    LoginUserInfo.LoginActionApi(
        account,
        password,
        function(response, err)
            loginResponse(response, err, handleLogined)
        end
    )
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
    
        if (PWD[3]) then
            info.loginServer = PWD[3]
        end
    
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
            loginResponse(response, err, callback)
        end
    )

    return true
end

function LoginUserInfo.OnClickLogin()
    Store:set('user/ignoreAutoLogin', true)
    LoginMain.ShowLoginModalImp()
end

function LoginUserInfo.setAutoLogin()
    local LoginModalImp = Store:get('page/LoginModal')

    if (not LoginModalImp) then
        return false
    end

    local autoLogin = LoginModalImp:GetValue('autoLogin')
    local loginServer = LoginModalImp:GetValue('loginServer')
    local account = LoginModalImp:GetValue('account')
    local password = LoginModalImp:GetValue('password')
    local rememberMe = LoginModalImp:GetValue('rememberPassword')

    if (autoLogin) then
        LoginModalImp:SetValue("rememberPassword", true)
        LoginModalImp:SetValue("autoLogin", true)
    else
        LoginModalImp:SetValue("rememberPassword", rememberMe)
        LoginModalImp:SetValue("autoLogin", false)
    end

    LoginModalImp:SetValue('loginServer', loginServer)
    LoginModalImp:SetValue('account', account)
    LoginModalImp:SetValue('password', password)

    LoginMain.refreshLoginModalImp()
end

function LoginUserInfo.LoginActionApi(account, password, callback)
    local url = format("%s/api/wiki/models/user/login", LoginUserInfo.site())

    local params = {
        username = account,
        password = password
    }

    loginRequest(url, params, {}, callback)
end

-- return nil or user token in url protocol
function LoginUserInfo.GetUserTokenFromUrlProtocol()
    local cmdline = ParaEngine.GetAppCommandLine()
    local urlProtocol = string.match(cmdline or "", "paracraft://(.*)$")
    urlProtocol = string.gsub(urlProtocol or "", "%%22", '"')

    local usertoken = urlProtocol:match('usertoken="([%S]+)"')
    return usertoken;
end

function LoginUserInfo.GetCurrentUserToken()
    return System.User and System.User.keepworktoken;
end

function LoginUserInfo.LoginWithTokenApi(callback)
    local usertoken = LoginUserInfo.GetUserTokenFromUrlProtocol() or LoginUserInfo.GetCurrentUserToken();
    return LoginUserInfo.LoginWithToken(usertoken, callback)
end

-- @param usertoken: keepwork user token
function LoginUserInfo.LoginWithToken(usertoken, callback)
    if (type(usertoken) == "string" and #usertoken > 0) then
        MsgBox:Show(L"正在登陆，请稍后...")

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

                    loginResponse(params, err, callback)
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