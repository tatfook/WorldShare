--[[
Title: Keepwork Applies API
Author(s):  big
Date:  2020.08.17
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkAppliesApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Applies.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkAppliesApi = NPL.export()

-- /applies?objectId={ojectId}&objectType={objectType}&applyType={applyType}
-- method: GET
-- params:
--[[
    objectId number necessary object id
    objectType number necessary ENTITY_TYPE_USER: 0, // 用户类型 ENTITY_TYPE_SITE: 1, // 站点类型 ENTITY_TYPE_PAGE: 2, // 页面类型 ENTITY_TYPE_GROUP: 3, // 组 ENTITY_TYPE_ISSUE: 4, // 问题 ENTITY_TYPE_PROJECT: 5, // 项目
    applyType number 0
]]
-- return: object
function KeepworkAppliesApi:Applies(objectId, objectType, applyType, success, error)
    if not objectId or not objectType or not applyType then
        return false
    end

    KeepworkBaseApi:Get(
        '/applies?objectId=' .. objectId ..
        '&objectType=' .. objectType ..
        '&applyType=' .. applyType,
        nil,
        nil,
        success,
        error
    )
end

-- url: /applies/:id
-- method: PUT
-- params:
--[[
    id number necessary apply id
    state number necessary  1 通过 2 拒绝
]]
-- return: object
function KeepworkAppliesApi:AppliesId(id, isAllow, success, error)
    if not id then
        return false
    end
    
    local state

    if isAllow == true then
        state = 1
    elseif isAllow == false then
        state = 2
    else
        return false
    end

    KeepworkBaseApi:Put("/applies/" .. id, { state = state }, nil, success, error)
end

-- url: /applies
-- method: POST
-- params:
--[[
    objectId integer necessary
    objectType integer necessary 枚举: 5 mock: 5
    applyType integer necessary 枚举: 0 mock: 0
    applyId	integer necessary
    legend string not necessary 最大长度: 255
]]
-- return: object
function KeepworkAppliesApi:PostApplies(objectId, objectType, applyType, applyId, legend, success, error)
    if not objectId or
       not objectType or
       not applyType or
       not applyId then
        return false
    end

    local params = {
        objectId = objectId,
        objectType = objectType,
        applyType = applyType,
        applyId = applyId,
        legend = legend
    }

    KeepworkBaseApi:Post("/applies", params, nil, success, error)
end