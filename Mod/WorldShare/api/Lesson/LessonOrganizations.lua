--[[
Title: Lesson Organizations API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local LessonOrganizationsApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/LessonOrganizations.lua")
------------------------------------------------------------
]]

local LessonBaseApi = NPL.load('./BaseApi.lua')

local LessonOrganizationsApi = NPL.export()

-- url: /lessonOrganizations/userOrgInfo
-- method: GET
-- params:
-- return: { message = '', data = { showOrgId = 1, allOrgs = {} }}
function LessonOrganizationsApi:GetUserAllOrgs(success, error)
    LessonBaseApi:Get("/lessonOrganizations/userOrgInfo", nil, nil, success, error)
end