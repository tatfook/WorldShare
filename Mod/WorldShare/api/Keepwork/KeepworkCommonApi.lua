--[[
Title: Keepwork Holiday API
Author(s): big
Date: 2022.5.6
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkCommonApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkCommonApi.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkCommonApi = NPL.export()

-- url: /holiday
-- method: GET
-- params:
--[[
    date datetime not necessary 查询日期
]]
-- return:
--[[
    isHoliday boolean not necessary 是否为假期日
]]
function KeepworkCommonApi:Holiday(date, success, error)
    KeepworkBaseApi:Get('/holiday', { date = date }, nil, success, error)
end
