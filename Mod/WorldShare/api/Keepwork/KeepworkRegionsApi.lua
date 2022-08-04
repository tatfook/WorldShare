--[[
Title: Keepwork Regions API
Author(s):  big
CreateDate: 2020.7.7
ModifyDate: 2022.8.4
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkRegionsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkRegionsApi.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkRegionsApi = NPL.export()

-- url: /regions
-- method: GET
-- params:
--[[
    parentId int not necessary 父id
]]
-- return:
--[[
    id number necessary
    parentId number necessary
    name string necessary
    level number necessary 1.国家 2.省 3.市 4.区
]]
function KeepworkRegionsApi:GetList(success, error)
    KeepworkBaseApi:Get('/regions', nil, nil, success, error)
end