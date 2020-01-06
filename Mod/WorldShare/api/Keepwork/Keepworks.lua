--[[
Title: Keepwork Keepworks API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkKeepworksApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Keepworks.lua")
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