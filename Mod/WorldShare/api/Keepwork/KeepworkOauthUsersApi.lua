--[[
Title: Keepwork Oauth Users API
Author(s): big
CreateDate: 2020.7.1
ModifyDate: 2022.8.4
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkOauthUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkOauthUsersApi.lua")
------------------------------------------------------------
]]
local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkOauthUsersApi = NPL.export()

-- url: /oauth_users/:plat
-- method: POST
-- params:
--[[
    plat string necessary qq、wechat、xinlang、github
    clientId string necessary xxxxxxxx
    state string necessary login
    code string necessary auth code	
    machineCode	string not necessary 
    platform string	not necessary
]]
-- return: object
function KeepworkOauthUsersApi:GetOauthUsers(platform, clientId, code, success, error)
    if type(platform) ~= "string" or type(code) ~= "string" then
        return false
    end

    if platform == "wechat" then
        platform = "weixin"
    end

    local url = "/oauth_users/" .. platform
    local params = {
        state = "login",
        code = code,
        clientId = clientId,
        redirectUri = "https://keepwork.com"
    }

    KeepworkBaseApi:Post(url, params, nil, success, error)
end