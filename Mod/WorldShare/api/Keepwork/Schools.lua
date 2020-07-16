--[[
Title: Keepwork Schools API
Author(s):  big
Date:  2020.7.7
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkSchoolsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Schools.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkSchoolsApi = NPL.export()

-- url: /schools
-- method: GET
-- headers: 
--[[
    x-per-page int necessary	
    x-page int necessary
]]
-- params:
--[[
    name string not necessary 根据学校名称模糊匹配
    regionId int not necessary
    type string not necessary 小学、中学、大学
]]
-- return:
--[[
    count number 总数
    rows object [] necessary
        item object
        id integer necessary
        name string necessary
        regionId integer necessary	
        type string necessary	
        orgId integer not necessary
        region object necessary
]]
function KeepworkSchoolsApi:GetList(name, regionId, type, success, error)
    local params = {}

    if name then
        params.name = name
    end

    if regionId then
        params.regionId = regionId
    end

    if type then
        params.type = Mod.WorldShare.Utils.EncodeURIComponent(type)
    end

    KeepworkBaseApi:Get('/schools', params, nil, success, error)
end
