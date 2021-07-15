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
    id int not necessary
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
function KeepworkSchoolsApi:GetList(name, regionId, regionType, success, error)
    local params = {}

    if name then
        params.name = Mod.WorldShare.Utils.EncodeURIComponent(name)
    end

    if regionId then
        params.regionId = regionId
    end

    if regionType then
        params.type = Mod.WorldShare.Utils.EncodeURIComponent(regionType)
    end

    KeepworkBaseApi:Get('/schools', params, nil, success, error)
end

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
    id int not necessary
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
function KeepworkSchoolsApi:GetSchoolById(id, success, error)
    local params = {}

    if type(id) ~= 'number' then
        return
    end

    params.id = id

    KeepworkBaseApi:Get('/schools', params, nil, success, error)
end

-- url: /schools/:id/classes
-- method: GET
-- params:
--[[
    id int schoolId necessary
]]
-- return:
--[[
]]
function KeepworkSchoolsApi:Classes(schoolId, success, error)
    KeepworkBaseApi:Get('/schools/' .. schoolId .. '/classes', nil, nil, success, error)
end
