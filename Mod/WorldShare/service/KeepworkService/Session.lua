--[[
Title: KeepworkService Session
Author(s):  big
Date:  2019.09.22
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
------------------------------------------------------------
]]

local KeepworkService = NPL.load("../KeepworkService.lua")
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Users.lua")
local KeepworkKeepworksApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Keepworks.lua")
local LessonOrganizationsApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/LessonOrganizations.lua")
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")
local GitGatewayService = NPL.load("../GitGatewayService.lua")
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")

local Encoding = commonlib.gettable("commonlib.Encoding")

local KeepworkServiceSession = NPL.export()

KeepworkServiceSession.captchaKey = ''

function KeepworkServiceSession:Login(account, password, callback)
    KeepworkUsersApi:Login(account, password, callback, callback)
end

function KeepworkServiceSession:LoginResponse(response, err, callback)
    if err == 400 then
        Mod.WorldShare.MsgBox:Close()
        GameLogic.AddBBS(nil, L"用户名或者密码错误", 3000, "255 0 0")
        return false
    end

    if type(response) ~= "table" then
        Mod.WorldShare.MsgBox:Close()
        GameLogic.AddBBS(nil, L"服务器连接失败", 3000, "255 0 0")
        return false
    end

    local token = response["token"] or ""
    local userId = response["id"] or 0
    local username = response["username"] or ""
    local nickname = response["nickname"] or ""

    local SetUserinfo = Mod.WorldShare.Store:Action("user/SetUserinfo")
    SetUserinfo(token, userId, username, nickname)

    if not response.cellphone and not response.email then
        Mod.WorldShare.Store:Set("user/isVerified", false)
    else
        Mod.WorldShare.Store:Set("user/isVerified", true)
    end

    if response.vip and response.vip == 1 then
        Mod.WorldShare.Store:Set("user/userType", 'vip')
    elseif response.tLevel and response.tLevel > 0 then
        Mod.WorldShare.Store:Set("user/userType", 'teacher')
        Mod.WorldShare.Store:Set("user/tLevel", response.tLevel)
    else
        Mod.WorldShare.Store:Set("user/userType", 'plain')
    end

    LessonOrganizationsApi:GetUserAllOrgs(
        function(data, err)
            if err == 200 then
                if data and data.data and type(data.data.allOrgs) == 'table' and type(data.data.showOrgId) == 'number' then
                    for key, item in ipairs(data.data.allOrgs) do
                        if item.id == data.data.showOrgId then
                            Mod.WorldShare.Store:Set('user/myOrg', item)
                        end
                    end
                end
            end

            if type(callback) == "function" then
                callback()
            end
        end
    )
end

function KeepworkServiceSession:Logout()
    if KeepworkService:IsSignedIn() then
        local Logout = Mod.WorldShare.Store:Action("user/Logout")
        Logout()
    end
end

function KeepworkServiceSession:Register(username, password, captcha, cellphone, cellphoneCaptcha, callback)
    if not username or not password or not captcha then
        return false
    end

    if type(username) ~= 'string' or
       type(password) ~= 'string' or
       type(captcha) ~= 'string' or
       type(cellphone) ~= 'string' or
       type(cellphoneCaptcha) ~= 'string' then
        return false
    end

    local params = {
        username = username,
        password = password,
        key = self.captchaKey,
        captcha = captcha,
        channel = 3
    }

    KeepworkUsersApi:Register(
        params,
        function(registerData, err)
            if registerData.id then
                self:Login(
                    username,
                    password,
                    function(loginData, err)
                        if err ~= 200 then
                            registerData.message = L'注册成功，登录失败，实名认证失败'
                            registerData.code = 9

                            if type(callback) == 'function' then
                                callback(registerData)
                            end

                            return false
                        end

                        self:LoginResponse(loginData, err, function()
                            self:SaveSigninInfo(
                                {
                                    account = username,
                                    password = password,
                                    token = loginData["token"] or "",
                                    loginServer = KeepworkService:GetEnv(),
                                    autoLogin = false,
                                    rememberMe = false
                                }
                            )

                            if #cellphone == 11 then
                                KeepworkUsersApi:RealName(
                                    {
                                        cellphone = cellphone,
                                        captcha = cellphoneCaptcha,
                                        realname = true
                                    },
                                    function(validatedData, err)
                                        if err == 200 then
                                            if type(callback) == 'function' then
                                                callback(registerData)
                                            end
                                            return true
                                        end
                                    end,
                                    function(data, err)
                                        registerData.message = '注册成功，实名认证失败'
                                        registerData.code = 10

                                        if type(callback) == 'function' then
                                            callback(registerData)
                                        end 
                                    end,
                                    { 400 }
                                )
                            else
                                if type(callback) == 'function' then
                                    callback(registerData)
                                end 
                            end
                        end)
                    end
                )
                return true
            end

            if type(callback) == 'function' then
                callback(registerData)
            end
        end,
        function(data, err)
            if type(callback) == 'function' then
                callback(data)
            end
        end,
        { 400 }
    )
end

function KeepworkServiceSession:FetchCaptcha(callback)
    KeepworkKeepworksApi:FetchCaptcha(function(data, err)
        if err == 200 and type(data) == 'table' then
            self.captchaKey = data.key

            if type(callback) == 'function' then
                callback()
            end
        end
    end)
end

function KeepworkServiceSession:GetCaptcha()
    if not self.captchaKey or type(self.captchaKey) ~= 'string' then
        return ''
    end

    return KeepworkService:GetCoreApi() .. '/keepworks/captcha/' .. self.captchaKey
end

function KeepworkServiceSession:GetPhoneCaptcha(phone, callback)
    if not phone or type(phone) ~= 'string' then
        return false
    end

    KeepworkUsersApi:CellphoneCaptcha(phone, callback, callback)
end

function KeepworkServiceSession:BindPhone(cellphone, captcha, callback)
    if not cellphone or type(cellphone) ~= 'string' or not captcha or type(captcha) ~= 'string' then
        return false
    end

    KeepworkUsersApi:BindPhone({
        cellphone = cellphone,
        captcha = captcha,
        isBind = true
    }, callback)
end

function KeepworkServiceSession:GetEmailCaptcha(email, callback)
    if not email or type(email) ~= 'string' then
        return false
    end

    KeepworkUsersApi:EmailCaptcha(email, callback)
end

function KeepworkServiceSession:BindEmail(email, captcha, callback)
    if not email or type(email) ~= 'string' or not captcha or type(captcha) ~= 'string' then
        return false
    end

    KeepworkUsersApi:BindEmail({
        email = email,
        captcha = captcha,
        isBind = true
    }, callback)
end

function KeepworkServiceSession:ResetPassword(key, password, captcha, callback)
    if type(key) ~= 'string' or type(password) ~= 'string' or type(captcha) ~= 'string' then
        return false
    end

    KeepworkUsersApi:ResetPassword({
        key = key,
        password = password,
        captcha = captcha
    }, callback, nil, { 400 })
end

-- @param usertoken: keepwork user token
function KeepworkServiceSession:Profile(callback, token)
    KeepworkUsersApi:Profile(token, callback, callback)
end

function KeepworkServiceSession:GetCurrentUserToken()
    if Mod.WorldShare.Store:Get("user/token") then
        return Mod.WorldShare.Store:Get("user/token")
    else
        return System.User and System.User.keepworktoken
    end
end

-- @param info: if nil, we will delete the login info.
function KeepworkServiceSession:SaveSigninInfo(info)
    if not info then
        return false
    end

    if not info.rememberMe then
        info.password = nil
    end

    SessionsData:SaveSession(info)
end

-- @return nil if not found or {account, password, loginServer, autoLogin}
function KeepworkServiceSession:LoadSigninInfo()
    local sessionsData = SessionsData:GetSessions()

    if sessionsData and sessionsData.selectedUser then
        for key, item in ipairs(sessionsData.allUsers) do
            if item.value == sessionsData.selectedUser then
                return item.session
            end
        end
    else
        return nil
    end
end

-- return nil or user token in url protocol
function KeepworkServiceSession:GetUserTokenFromUrlProtocol()
    local cmdline = ParaEngine.GetAppCommandLine()
    local urlProtocol = string.match(cmdline or "", "paracraft://(.*)$")
    urlProtocol = Encoding.url_decode(urlProtocol or "")

    local usertoken = urlProtocol:match('usertoken="([%S]+)"')

    if usertoken then
        local SetToken = Mod.WorldShare.Store:Action("user/SetToken")
        SetToken(usertoken)
    end
end
