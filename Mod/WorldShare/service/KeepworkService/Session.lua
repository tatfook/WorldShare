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

function KeepworkServiceSession:IsSignedIn()
    local token = Mod.WorldShare.Store:Get("user/token")

    return token ~= nil
end

function KeepworkServiceSession:Login(account, password, callback)
    KeepworkUsersApi:Login(account, password, callback, callback)
end

function KeepworkServiceSession:LoginWithToken(token, callback)
    KeepworkUsersApi:Profile(token, callback, callback)
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

    local token = response["token"] or System.User.keepworktoken
    local userId = response["id"] or 0
    local username = response["username"] or ""
    local nickname = response["nickname"] or ""

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

    local SetUserinfo = Mod.WorldShare.Store:Action("user/SetUserinfo")
    SetUserinfo(token, userId, username, nickname)

    local userWorldsFolder = 'worlds/' .. username

    if System.os.GetExternalStoragePath() ~= "" then
        ParaIO.CreateDirectory(System.os.GetExternalStoragePath() .. "paracraft/" .. userWorldsFolder .. '/')
    else
        ParaIO.CreateDirectory(ParaIO.GetWritablePath() .. userWorldsFolder .. '/')
    end

    Mod.WorldShare.Store:Set('world/myWorldsFolder', 'worlds/' .. username)

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
end

function KeepworkServiceSession:Logout()
    if KeepworkService:IsSignedIn() then
        local Logout = Mod.WorldShare.Store:Action("user/Logout")
        Logout()
        self:ResetIndulge()
        Mod.WorldShare.Store:Set('world/myWorldsFolder', 'worlds/DesignHouse')
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
    }, callback, callback)
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
end

function KeepworkServiceSession:CheckTokenExpire(callback)
    if not KeepworkService:IsSignedIn() then
        return false
    end
    
    local token = Mod.WorldShare.Store:Get('user/token')
    local tokeninfo = System.Encoding.jwt.decode(token)
    local exp = tokeninfo.exp and tokeninfo.exp or 0

    local function ReEntry()
        self:Logout()

        local currentUser = self:LoadSigninInfo()

        if not currentUser or not currentUser.account or not currentUser.password then
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
    if exp <= (os.time() + 1 * 24 * 3600) then
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
        self.gameTime = (self.gameTime or 0) + 1 * 60

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

function KeepworkServiceSession:IsMyWorldsFolder()
    local username = Mod.WorldShare.Store:Get('user/username') or ""
    local myWorldsFolder = Mod.WorldShare.Store:Get('world/myWorldsFolder') or ""
    local myWorldsFolderUsername = string.match(myWorldsFolder, '^worlds/(.+)') or ""

    if username == "" or myWorldsFolderUsername == "" then
        return false
    end

    if username == myWorldsFolderUsername then
        return true
    else
        return false
    end
end

function KeepworkServiceSession:IsMyTempWorldsFolder()
    local myWorldsFolder = Mod.WorldShare.Store:Get('world/myWorldsFolder') or ""
    local myWorldsFolderUsername = string.match(myWorldsFolder, '^worlds/(.+)') or ""

    if myWorldsFolderUsername == "" then
        return false
    end

    if myWorldsFolderUsername == 'DesignHouse' then
        return true
    else
        return false
    end
end

function KeepworkServiceSession:IsCurrentWorldsFolder()
    local username = Mod.WorldShare.Store:Get('user/username') or ""
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    local myWorldsFolderUsername = ""

    if currentWorld and currentWorld.worldpath then
        myWorldsFolderUsername = string.match(currentWorld.worldpath, 'worlds/(%w+)/') or ""
    end

    if username == "" or myWorldsFolderUsername == "" then
        return false
    end

    if username == myWorldsFolderUsername then
        return true
    else
        return false
    end
end

function KeepworkServiceSession:IsTempWorldsFolder()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    local myWorldsFolderUsername = ""

    if currentWorld and currentWorld.worldpath then
        myWorldsFolderUsername = string.match(currentWorld.worldpath, 'worlds/(%w+)/') or ""
    end

    if myWorldsFolderUsername == 'DesignHouse' then
        return true
    else
        return false
    end
end
