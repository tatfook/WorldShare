--[[
Title: Keepwork Members API
Author(s):  big
Date:  2020.03.31
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkMembersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Members.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkMembersApi = NPL.export()

-- url: //members?objectId={objectId}&objectType={objectType}
-- method: GET
-- params:
--[[
    objectId number necessary object id
    objectType number necessary ENTITY_TYPE_USER: 0, // 用户类型 ENTITY_TYPE_SITE: 1, // 站点类型 ENTITY_TYPE_PAGE: 2, // 页面类型 ENTITY_TYPE_GROUP: 3, // 组 ENTITY_TYPE_ISSUE: 4, // 问题 ENTITY_TYPE_PROJECT: 5, // 项目
]]
-- return: object
function KeepworkMembersApi:Members(objectId, objectType, success, error)
    if not objectId or not objectType then
        return false
    end

    KeepworkBaseApi:Get('/members?objectId=' .. objectId .. '&objectType=' .. objectType, nil, nil, success, error)
end

-- url: /members/:id
-- method: DELETE
-- params:
--[[
    id number necessary member table id
]]
-- return: string
function KeepworkMembersApi:DeleteMembersId(id, success, error)
    if not id then
        return false
    end

    KeepworkBaseApi:Delete('/members/'.. id, nil, nil, success, error)
end

-- url: /members/bulk
-- method: POST
-- params:
--[[
    objectId integer necessary
    objectType integer necessary 枚举: 1,3,5 枚举备注: 1 site 3 group 5 project
    memberIds integer [] not necessary item 类型: integer
]]
-- return: object
function KeepworkMembersApi:Bulk(objectId, objectType, memberIds, success, error)
    if not objectId or not objectType or not memberIds or #memberIds == 0 then
        return false
    end

    local params = {
        objectId = objectId,
        objectType = objectType,
        memberIds = memberIds
    }

    KeepworkBaseApi:Post('/members/bulk', params, nil, success, error)
end
