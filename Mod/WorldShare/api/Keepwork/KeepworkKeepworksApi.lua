--[[
Title: Keepwork Keepworks API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkKeepworksApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkKeepworksApi.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua')

local KeepworkKeepworksApi = NPL.export()

-- url: /keepworks/svg_captcha?png=true
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkKeepworksApi:FetchCaptcha(success, error)
    KeepworkBaseApi:Get('/keepworks/svg_captcha?png=true', nil, { notTokenRequest = true }, success, error)
end

-- url: /keepworks/svg_captcha
-- method: POST
-- params:
--[[
    key string necessary
    captcha string necessary
]]
-- return: object
function KeepworkKeepworksApi:SvgCaptcha(key, captcha, success, error)
    local params = {
        key = key,
        captcha = captcha
    }

    KeepworkBaseApi:Post('/keepworks/svg_captcha', params, { notTokenRequest = true }, success, error)
end