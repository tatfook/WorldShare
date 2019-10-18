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

local KeepworkServiceSession = NPL.export()

KeepworkServiceSession.captchaKey = ''

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

    KeepworkService:Request(
        '/users/register',
        'POST',
        params,
        nil,
        function (registerData, err)
            if err == 200 and registerData.id then
                KeepworkService:Login(
                    username,
                    password,
                    function(loginData, err)
                        if err ~= 200 then
                            registerData.message = '注册成功，登录失败，实名认证失败'
                            registerData.code = 9

                            if type(callback) == 'function' then
                                callback(registerData)
                            end

                            return false
                        end

                        KeepworkService:LoginResponse(loginData, err, function()
                            KeepworkService:SaveSigninInfo(
                                {
                                    account = username,
                                    password = password,
                                    token = loginData["token"] or "",
                                    loginServer = Mod.WorldShare.Store:Get('user/env'),
                                    autoLogin = false,
                                    rememberMe = false
                                }
                            )

                            if #cellphone == 11 then
                                KeepworkService:Request(
                                    '/users/cellphone_captcha',
                                    'POST',
                                    {
                                        cellphone = cellphone,
                                        captcha = cellphoneCaptcha,
                                        realname = true
                                    },
                                    KeepworkService:GetHeaders(),
                                    function(validatedData, err)
                                        if err == 200 then
                                            if type(callback) == 'function' then
                                                callback(registerData)
                                            end
                                            return true
                                        end

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
        { 400 }
    )
end

function KeepworkServiceSession:FetchCaptcha(callback)
    KeepworkService:Request(
        '/keepworks/svg_captcha?png=true',
        "GET",
        nil,
        nil,
        function (data, err)
            if err == 200 and type(data) == 'table' then
                self.captchaKey = data.key

                if type(callback) == 'function' then
                    callback()
                end
            end
        end
    )
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

    KeepworkService:Request(
        '/users/cellphone_captcha?cellphone=' .. phone,
        'GET',
        nil,
        nil,
        callback
    )
end

function KeepworkServiceSession:BindPhone(cellphone, captcha, callback)
    if not cellphone or type(cellphone) ~= 'string' or not captcha or type(captcha) ~= 'string' then
        return false
    end

    KeepworkService:Request(
        '/users/cellphone_captcha',
        'POST',
        {
            cellphone = cellphone,
            captcha = captcha,
            isBind = true
        },
        KeepworkService:GetHeaders(),
        callback
    )
end

function KeepworkServiceSession:GetEmailCaptcha(email, callback)
    if not email or type(email) ~= 'string' then
        return false
    end

    KeepworkService:Request(
        '/users/email_captcha?email=' .. email,
        'GET',
        nil,
        nil,
        callback
    )
end

function KeepworkServiceSession:BindEmail(email, captcha, callback)
    if not email or type(email) ~= 'string' or not captcha or type(captcha) ~= 'string' then
        return false
    end

    KeepworkService:Request(
        '/users/email_captcha',
        'POST',
        {
            email = email,
            captcha = captcha,
            isBind = true
        },
        KeepworkService:GetHeaders(),
        callback
    )
end

function KeepworkServiceSession:ResetPassword(key, password, captcha, callback)
    if type(key) ~= 'string' or type(password) ~= 'string' or type(captcha) ~= 'string' then
        return false
    end

    KeepworkService:Request(
        '/users/reset_password',
        'POST',
        {
            key = key,
            password = password,
            captcha = captcha
        },
        nil,
        callback,
        { 400 }
    )
end