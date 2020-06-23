--[[
Title: Keepwork Users API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Users.lua")
------------------------------------------------------------
]]
local Encoding = commonlib.gettable("System.Encoding.basexx")

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkUsersApi = NPL.export()

-- url: /users/login
-- method: POST
-- params:
--[[
    account	string 必须 用户名	
    password string 必须 密码
]]
-- return: object
function KeepworkUsersApi:Login(account, password, platform, machineCode, success, error)
    if type(account) ~= "string" or type(password) ~= "string" then
        return false
    end

    local params = {
        username = account,
        password = password,
        platform = platform,
        machineCode = machineCode
    }

    KeepworkBaseApi:Post("/users/login", params, nil, success, error, { 503, 400 })
end

-- url: /users/logout
-- method: POST
-- params: []
-- return: object
function KeepworkUsersApi:Logout(success, error)
    KeepworkBaseApi:Post("/users/logout", nil, nil, success, error)
end

-- url: /users/profile
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:Profile(token, success, error)
    if type(token) ~= "string" and #token == 0 then
        return false
    end

    local headers = { Authorization = format("Bearer %s", token) }

    KeepworkBaseApi:Get("/users/profile", nil, headers, success, error, 401)
end

-- url: /users/register
-- method: POST
-- params:
--[[
    token string 必须 token
    username string 必须 username,
    password string 必须 password,
    key string 必须 captchaKey,
    captcha string 必须 captcha,
    channel = 3
]]
-- return: object
function KeepworkUsersApi:Register(params, success, error, noTryStatus)
    KeepworkBaseApi:Post('/users/register', params, { notTokenRequest = true }, success, error, noTryStatus)
end

-- url: /users/svg_captcha?png=true
-- method: GET
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:FetchCaptcha(success, error)
    KeepworkBaseApi:Get('/users/svg_captcha?png=true', nil, { notTokenRequest = true }, success, error)
end


-- url: /users/cellphone_captcha
-- method: GET
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:CellphoneCaptcha(phone, success, error)
    if type(phone) ~= 'string' then
        return false
    end

    local url = '/users/cellphone_captcha?cellphone=' .. phone

    KeepworkBaseApi:Get(url, nil, { notTokenRequest = true }, success, error)
end

-- url: /users/cellphone_captcha
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:RealName(cellphone, captcha, success, error, noTryStatus)
    local params = {
        cellphone = cellphone,
        captcha = captcha,
        realname = true
    }

    KeepworkBaseApi:Post('/users/cellphone_captcha', params, nil, success, error, noTryStatus)
end

-- url: /users/cellphone_captcha
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:BindPhone(cellphone, captcha, success, error)
    local params = {
        cellphone = cellphone,
        captcha = captcha,
        isBind = true
    }

    KeepworkBaseApi:Post('/users/cellphone_captcha', params , { notTokenRequest = false }, success, error)
end

-- url: /users/cellphone_captcha
-- method: POST
-- params:
--[[

]]
-- return: object
function KeepworkUsersApi:ClassificationAndBindPhone(cellphone, captcha, success, error)
    local params = {
        cellphone = cellphone,
        captcha = captcha,
        realname = true,
        isBind = true
    }

    KeepworkBaseApi:Post('/users/cellphone_captcha', params , { notTokenRequest = false }, success, error)
end

-- url: /users/email_captcha
-- method: GET
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:EmailCaptcha(email, success, error)
    local url = '/users/email_captcha?email=' .. email

    KeepworkBaseApi:Get(url, nil, { notTokenRequest = true }, success, error)
end

-- url: /users/email_captcha
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:BindEmail(params, success, error)
    KeepworkBaseApi:Post('/users/email_captcha', params, { notTokenRequest = false }, success, error)
end

-- url: /users/reset_password
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:ResetPassword(params, success, error, noTryStatus)
    KeepworkBaseApi:Post('/users/reset_password', params, { notTokenRequest = true }, success, error, noTryStatus)
end

-- url: /users?cellphone=<the phone number>
-- method: GET
-- return: object
function KeepworkUsersApi:GetUserByPhonenumber(phonenumber, success, error)
    if not phonenumber then
        return false
    end

    KeepworkBaseApi:Get('/users?cellphone=' .. phonenumber, nil, nil, success, error)
end

-- url: /users/PP{username base 64}
-- method: GET
-- return: object
function KeepworkUsersApi:GetUserByUsernameBase64(username, success, error)
    if type(username) ~= "string" then
        return false
    end

    if #username == 0 then
        return false
    end

    local usernameBase64 = Encoding.to_base64(NPL.ToJson({username = username}))

    KeepworkBaseApi:Get('/users/PP' .. usernameBase64, nil, nil, success, error)
end

-- url: /users?email={email}
-- method: GET
-- return: object
function KeepworkUsersApi:GetUserByEmail(email, success, error)
    if type(email) ~= "string" then
        return false
    end

    if #email == 0 then
        return false
    end

    KeepworkBaseApi:Get('/users?email=' .. email, nil, nil, success, error)
end

-- url: users/refreshToken
-- method: GET
-- return: object
function KeepworkUsersApi:RefreshToken(success, error)
    KeepworkBaseApi:Get('/users/refreshToken', nil, nil, success, error)
end