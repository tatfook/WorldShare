--[[
Title: Accounting Org Activate Code API
Author(s):  big
Date:  2020.9.27
Place: Foshan
use the lib:
------------------------------------------------------------
local AccountingOrgActivateCodeApi = NPL.load("(gl)Mod/WorldShare/api/Accounting/OrgActivateCode.lua")
------------------------------------------------------------
]]

local AccountingBaseApi = NPL.load('./BaseApi.lua')

local AccountingOrgActivateCodeApi = NPL.export()

-- url: /orgActivateCode/activate
-- method: POST
-- params:
--[[
    key string not necessary 激活码
    realname string not necessary 名字
]]
-- return: 
function AccountingOrgActivateCodeApi:Activate(key, realname, success, error)
    if not key or not realname then
        return false
    end

    local params = {
        key = key,
        realname = realname
    }

    AccountingBaseApi:Post("/orgActivateCode/activate", params, nil, success, error)
end