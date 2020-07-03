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

-- service
local KeepworkService = NPL.load("../KeepworkService.lua")
local GitGatewayService = NPL.load("../GitGatewayService.lua")
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua")

-- api
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Users.lua")
local KeepworkKeepworksApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Keepworks.lua")
local LessonOrganizationsApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/LessonOrganizations.lua")
local KeepworkSocketApi = NPL.load("(gl)Mod/WorldShare/api/Socket/Socket.lua")

-- database
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")

-- helper
local Validated = NPL.load("(gl)Mod/WorldShare/helper/Validated.lua")

local Encoding = commonlib.gettable("commonlib.Encoding")

local KeepworkServiceSession = NPL.export()

KeepworkServiceSession.captchaKey = ''

function KeepworkServiceSession:LongConnectionInit(callback)
    local connection = KeepworkSocketApi:Connect()

    if not connection then
        return false
    end

    if connection.inited then
        return nil
    end

    if not KpChatChannel.client then
        KpChatChannel.client = connection
    
        KpChatChannel.client:AddEventListener("OnOpen", KpChatChannel.OnOpen, KpChatChannel)
        KpChatChannel.client:AddEventListener("OnMsg", KpChatChannel.OnMsg, KpChatChannel)
        KpChatChannel.client:AddEventListener("OnClose", KpChatChannel.OnClose, KpChatChannel)
    end

    connection:AddEventListener("OnOpen", function(self)
        LOG.std("KeepworkServiceSession", "debug", "LongConnectionInit", "Connected client")
    end, connection)

    connection:AddEventListener("OnMsg", self.OnMsg, connection)
    connection.uiCallback = callback
    connection.inited = true
end

function KeepworkServiceSession:OnMsg(msg)
    LOG.std("KeepworkServiceSession", "debug", "OnMsg", "data: %s", NPL.ToJson(msg.data))

    if not msg or not msg.data then
        return false
    end

    if msg.data.sio_pkt_name and msg.data.sio_pkt_name == "event" then
        if msg.data.body and msg.data.body[1] == "app/msg" then

            local connection = KeepworkSocketApi:GetConnection()

            if type(connection.uiCallback) == "function" then
                connection.uiCallback(msg.data.body[2])
            end
        end
    end
end


function KeepworkServiceSession:LoginSocket()
    if not self:IsSignedIn() then
        return false
    end

    local platform

    if System.os.GetPlatform() == 'mac' or System.os.GetPlatform() == 'win32' then
        platform = "PC"
    else
        platform = "MOBILE"
    end

    local machineCode = SessionsData:GetDeviceUUID()
    KeepworkSocketApi:SendMsg("app/login", { platform = platform, machineCode = machineCode })
end

function KeepworkServiceSession:IsSignedIn()
    local token = Mod.WorldShare.Store:Get("user/token")
    local bLoginSuccessed = Mod.WorldShare.Store:Get("user/bLoginSuccessed")

    if token ~= nil and bLoginSuccessed then
        return true
    else
        return false
    end
end

function KeepworkServiceSession:Login(account, password, callback)
    local machineCode = SessionsData:GetDeviceUUID()
    local platform

    if System.os.GetPlatform() == 'mac' or System.os.GetPlatform() == 'win32' then
        platform = "PC"
    else
        platform = "MOBILE"
    end

    KeepworkUsersApi:Login(
        account,
        password,
        platform,
        machineCode,
        callback,
        callback
    )
end

function KeepworkServiceSession:LoginWithToken(token, callback)
    KeepworkUsersApi:Profile(token, callback, callback)
end

function KeepworkServiceSession:LoginResponse(response, err, callback)
    if err ~= 200 or type(response) ~= "table" then
        return false
    end

    -- login success ↓
    local token = response["token"] or System.User.keepworktoken
    local userId = response["id"] or 0
    local username = response["username"] or ""
    local nickname = response["nickname"] or ""

    if not response.realname then
        Mod.WorldShare.Store:Set("user/isVerified", false)
    else
        Mod.WorldShare.Store:Set("user/isVerified", true)
    end

    if not response.cellphone and not response.email then
        Mod.WorldShare.Store:Set("user/isBind", false)
    else
        Mod.WorldShare.Store:Set("user/isBind", true)
    end

    if response.orgAdmin and response.orgAdmin == 1 then
        Mod.WorldShare.Store:Set("user/userType", 'teacher')
    elseif response.tLevel and response.tLevel > 0 then
        Mod.WorldShare.Store:Set("user/userType", 'teacher')
        Mod.WorldShare.Store:Set("user/tLevel", response.tLevel)
    elseif response.student and response.student == 1 then
        Mod.WorldShare.Store:Set("user/userType", 'vip')
    elseif response.vip and response.vip == 1 then
        Mod.WorldShare.Store:Set("user/userType", 'vip')
    else
        Mod.WorldShare.Store:Set("user/userType", 'plain')
    end

    Mod.WorldShare.Store:Set('user/bLoginSuccessed', true)

    local tokenExpire

    if response.tokenExpire then
        tokenExpire = os.time() + tonumber(response.tokenExpire)
    end

    if response.mode ~= 'auto' then
        self:SaveSigninInfo(
            {
                account = username,
                password = response.password,
                loginServer = KeepworkService:GetEnv(),
                token = token,
                autoLogin = response.autoLogin,
                rememberMe = response.rememberMe,
                tokenExpire = tokenExpire
            }
        )
    end

    local Login = Mod.WorldShare.Store:Action("user/Login")
    Login(token, userId, username, nickname)

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

    self:ResetIndulge()
    self:LoginSocket()
end

function KeepworkServiceSession:Logout(mode, callback)
    if KeepworkService:IsSignedIn() then
        if not mode or mode ~= "KICKOUT" then
            KeepworkUsersApi:Logout(function()
                KeepworkSocketApi:SendMsg("app/logout", {})
                local Logout = Mod.WorldShare.Store:Action("user/Logout")
                Logout()
                self:ResetIndulge()
                Mod.WorldShare.Store:Remove('user/bLoginSuccessed')
                
                if type(callback) then
                    callback()
                end
            end)
        else
            KeepworkSocketApi:SendMsg("app/logout", {})
            local Logout = Mod.WorldShare.Store:Action("user/Logout")
            Logout()
            self:ResetIndulge()
            Mod.WorldShare.Store:Remove('user/bLoginSuccessed')

            if type(callback) then
                callback()
            end
        end
    end
end

function KeepworkServiceSession:Register(username, password, captcha, cellphone, cellphoneCaptcha, isBind, callback)
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

    local params

    if #cellphone == 11 then
        -- certification
        params = {
            username = username,
            password = password,
            captcha = cellphoneCaptcha,
            channel = 3,
            cellphone = cellphone,
            isBind = isBind
        }
    else
        -- no certification
        params = {
            username = username,
            password = password,
            key = self.captchaKey,
            captcha = captcha,
            channel = 3
        }
    end

    KeepworkUsersApi:Register(
        params,
        function(registerData, err)
            if registerData.id then
                self:Login(
                    username,
                    password,
                    function(loginData, err)
                        if err ~= 200 then
                            registerData.message = L'注册成功，登录失败'
                            registerData.code = 9

                            if type(callback) == 'function' then
                                callback(registerData)
                            end

                            return false
                        end

                        loginData.autoLogin = autoLogin
                        loginData.rememberMe = rememberMe
                        loginData.password = password

                        self:LoginResponse(loginData, err, function()
                            if type(callback) == 'function' then
                                callback(registerData)
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
                callback({ message = "", code = err})
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

function KeepworkServiceSession:ClassificationPhone(cellphone, captcha, callback)
    KeepworkUsersApi:RealName(cellphone, captcha, callback, callback, { 400 })
end

function KeepworkServiceSession:BindPhone(cellphone, captcha, callback)
    if not cellphone or type(cellphone) ~= 'string' or not captcha or type(captcha) ~= 'string' then
        return false
    end

    KeepworkUsersApi:BindPhone(cellphone, captcha, callback, callback)
end

function KeepworkServiceSession:ClassificationAndBindPhone(cellphone, captcha, callback)
    if not cellphone or type(cellphone) ~= 'string' or not captcha or type(captcha) ~= 'string' then
        return false
    end

    KeepworkUsersApi:ClassificationAndBindPhone(cellphone, captcha, callback, callback)
end

function KeepworkServiceSession:GetEmailCaptcha(email, callback)
    if not email or type(email) ~= 'string' then
        return false
    end

    KeepworkUsersApi:EmailCaptcha(email, callback, callback)
end

function KeepworkServiceSession:BindEmail(email, captcha, callback)
    if not email or type(email) ~= 'string' or not captcha or type(captcha) ~= 'string' then
        return false
    end

    KeepworkUsersApi:BindEmail({
        email = email,
        captcha = captcha,
        isBind = true
    }, callback, callback)
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

    return usertoken
end

function KeepworkServiceSession:CheckTokenExpire(callback)
    if not KeepworkService:IsSignedIn() then
        return false
    end

    local token = Mod.WorldShare.Store:Get('user/token')
    local info = self:LoadSigninInfo()

    local tokenExpire = info and info.tokenExpire or 0

    local function ReEntry()
        self:Logout()

        local currentUser = self:LoadSigninInfo()

        if not currentUser or not currentUser.account or not currentUser.password then
            if type(callback) == "function" then
                callback(false)
            end
            return false
        end

        self:Login(
            currentUser.account,
            currentUser.password,
            function(response, err)
                if err ~= 200 then
                    if type(callback) == "function" then
                        callback(false)
                    end
                    return false
                end

                self:LoginResponse(response, err, function()
                    if type(callback) == "function" then
                        callback(true)
                    end
                end)
            end
        )
    end

    -- we will not fetch token if token is expire
    if tokenExpire <= (os.time() + 1 * 24 * 3600) then
        ReEntry()
        return false
    end

    self:Profile(function(data, err)
        if err ~= 200 then
            ReEntry()
            return false
        end

        if type(callback) == "function" then
            callback(true)
        end
    end, token)
end

function KeepworkServiceSession:RenewToken()
    self:CheckTokenExpire()

    Mod.WorldShare.Utils.SetTimeOut(function()
        self:RenewToken()
    end, 3600 * 1000)
end

function KeepworkServiceSession:PreventIndulge(callback)
    local function Handle()
        local times = 1000
        self.gameTime = (self.gameTime or 0) + 1

        -- 40 minutes
        if self.gameTime == (40 * 60) then
            if type(callback) == 'function' then
                callback('40MINS')
            end
        end

        -- 2 hours
        if self.gameTime == (2 * 60 * 60) then
            if type(callback) == 'function' then
                callback('2HOURS')
            end
        end

        -- 4 hours
        if self.gameTime == (4 * 60 * 60) then
            if type(callback) == 'function' then
                callback('4HOURS')
            end
        end

        -- 22:30
        if os.date("%H:%M", os.time()) == '22:30' then
            if type(callback) == 'function' then
                callback('22:30')
            end

            times = 60 * 1000
        end

        Mod.WorldShare.Utils.SetTimeOut(function()
            Handle()
        end, times)
    end

    Handle()
end

function KeepworkServiceSession:ResetIndulge()
    self.gameTime = 0
end

function KeepworkServiceSession:CheckPhonenumberExist(phone, callback)
    if not phone or not Validated:Phone(phone) then
        return false
    end

    if type(callback) ~= "function" then
        return false
    end

    KeepworkUsersApi:GetUserByPhonenumber(
        phone,
        function(data, err)
            if data and #data > 0 then
                callback(true)
            else
                callback(false)
            end
        end,
        function() 
            callback(false)
        end
    )
end

function KeepworkServiceSession:CheckUsernameExist(username, callback)
    if type(username) ~= "string" then
        return false
    end

    if type(callback) ~= "function" then
        return false
    end

    KeepworkUsersApi:GetUserByUsernameBase64(
        username,
        function(data, err)
            if type(data) == 'table' then
                callback(true)
            else
                callback(false)
            end
        end,
        function(data, err)
            callback(false)
        end
    )
end

function KeepworkServiceSession:CheckEmailExist(email, callback)
    if type(email) ~= "string" then
        return false
    end

    if type(callback) ~= "function" then
        return false
    end

    KeepworkUsersApi:GetUserByEmail(
        email,
        function(data, err)
            if type(data) == 'table' and #data > 0 then
                callback(true)
            else
                callback(false)
            end
        end,
        function(data, err)
            callback(false)
        end
    )
end
