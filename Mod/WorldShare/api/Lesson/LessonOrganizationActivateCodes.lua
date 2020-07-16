--[[
Title: Lesson Organization Activate Codes API
Author(s):  big
Date:  2020.7.9
Place: Foshan
use the lib:
------------------------------------------------------------
local LessonOrganizationActivateCodesApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/LessonOrganizationActivateCodes.lua")
------------------------------------------------------------
]]

local LessonBaseApi = NPL.load('./BaseApi.lua')

local LessonOrganizationActivateCodesApi = NPL.export()

-- url: /lessonOrganizationActivateCodes/activate
-- method: POST
-- params:
--[[
    key string not necessary 激活码
    realname string not necessary 名字
]]
-- return: 
function LessonOrganizationActivateCodesApi:Activate(key, realname, success, error)
    if not key or not realname then
        return false
    end

    local params = {
        key = key,
        realname = realname
    }

    LessonBaseApi:Post("/lessonOrganizationActivateCodes/activate", params, nil, success, error)
end