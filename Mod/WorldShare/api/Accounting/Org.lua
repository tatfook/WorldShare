--[[
Title: Accounting Org API
Author(s):  big
Date:  2020.9.27
Place: Foshan
use the lib:
------------------------------------------------------------
local AccountingOrgApi = NPL.load("(gl)Mod/WorldShare/api/Accounting/Org.lua")
------------------------------------------------------------
]]

local AccountingBaseApi = NPL.load('./BaseApi.lua')

local AccountingOrgApi = NPL.export()

-- url: /org/userOrg
-- method: GET
-- params:
-- return: { message = '', data = { showOrgId = 1, allOrgs = {} }}
function AccountingOrgApi:GetUserAllOrgs(success, error)
    AccountingBaseApi:Get("/org/userOrg", nil, nil, success, error)
end