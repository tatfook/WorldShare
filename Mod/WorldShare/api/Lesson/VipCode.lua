--[[
Title: Vip Code API
Author(s):  big
Date:  2020.2.10
Place: Foshan
use the lib:
------------------------------------------------------------
local LessonVipCodeApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/VipCode.lua")
------------------------------------------------------------
]]

local LessonBaseApi = NPL.load('./BaseApi.lua')

local LessonVipCodeApi = NPL.export()

function LessonVipCodeApi:Activate(key, success, error)
    if type(key) ~= 'string' then
        return false
    end

    LessonBaseApi:Post("/vipCode/activate", { key = key }, nil, success, error)
end
