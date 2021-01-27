--[[
Title: filters
Author(s):  Big
Date: 2020.12.11
Desc: 
use the lib:
------------------------------------------------------------
local Filters = NPL.load('(gl)Mod/WorldShare/filters/Filters.lua')
Filters:Init()
------------------------------------------------------------
]]

-- load all filters
local SessionFilter = NPL.load('./service/KeepworkService/SessionFilter.lua')
local MySchoolFilter = NPL.load('./cellar/MySchool/MySchoolFilter.lua')
local VipNoticeFilter = NPL.load('./cellar/VipNotice/VipNoticeFilter.lua')
local ClientUpdateDialogFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/ClientUpdateDialog/ClientUpdateDialogFilter.lua')
local MsgBoxFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Common/MsgBox/MsgBoxFilter.lua')
local OnLoadBlockRegionFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/OnLoadBlockRegionFilter.lua')

local Filters = NPL.export()

function Filters:Init()
    -- init session filter
    SessionFilter:Init()

    -- init myschool filter
    MySchoolFilter:Init()

    -- init vip notice filter
    VipNoticeFilter:Init()

    -- init client update dialog filter
    ClientUpdateDialogFilter:Init()

    -- init msg box filter
    MsgBoxFilter:Init()

    -- init on load block region filter
    OnLoadBlockRegionFilter:Init()
end