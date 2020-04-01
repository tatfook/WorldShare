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

-- url: /keepworks/svg_captcha?png=true
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