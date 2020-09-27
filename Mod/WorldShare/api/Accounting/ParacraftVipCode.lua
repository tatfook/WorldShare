--[[
Title: Accounting Paracraft Vip Code API
Author(s):  big
Date:  2020.9.27
Place: Foshan
use the lib:
------------------------------------------------------------
local AccountingVipCodeApi = NPL.load("(gl)Mod/WorldShare/api/Accounting/ParacraftVipCode.lua")
------------------------------------------------------------
]]

local AccountingBaseApi = NPL.load('./BaseApi.lua')

local AccountingVipCodeApi = NPL.export()

function AccountingVipCodeApi:Activate(key, success, error)
    if type(key) ~= 'string' then
        return false
    end

    AccountingBaseApi:Post("/paracraftVipCode/activate", { key = key }, nil, success, error)
end
