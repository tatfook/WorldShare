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
--[[
    roleId number not necessray  0.获取自己加入的全部机构 1.获取自己学习的机构 2.获取自己任教的机构 4.获取自己管理的机构
    includeParaWorld boolean not necessary 是否包含大世界信息
]]
-- return: { message = '', data = { showOrgId = 1, allOrgs = {} }}
function AccountingOrgApi:GetUserAllOrgs(roleId, includeParaWorld, success, error)
    if not includeParaWorld or type(includeParaWorld) ~= 'boolean' then
        includeParaWorld = true
    end

    local params = {
        roleId = roleId or 0,
        includeParaWorld = includeParaWorld
    }

    AccountingBaseApi:Get("/org/userOrg", params, nil, success, error, nil, 8)
end