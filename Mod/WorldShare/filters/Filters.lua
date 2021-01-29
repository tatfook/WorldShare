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
local KeepworkServiceSessionFilter = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/KeepworkServiceSessionFilter.lua')
local MySchoolFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/MySchool/MySchoolFilter.lua')
local VipNoticeFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/VipNotice/VipNoticeFilter.lua')
local ClientUpdateDialogFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/ClientUpdateDialog/ClientUpdateDialogFilter.lua')
local MsgBoxFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Common/MsgBox/MsgBoxFilter.lua')
local OnWorldInitialRegionsLoadedFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/OnWorldInitialRegionsLoadedFilter.lua')
local WorldInfoFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/WorldInfoFilter.lua')
local LocalServiceWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/service/LocalService/LocalServiceWorldFilter.lua')

local Filters = NPL.export()

function Filters:Init()
    -- init session filter
    KeepworkServiceSessionFilter:Init()

    -- init myschool filter
    MySchoolFilter:Init()

    -- init vip notice filter
    VipNoticeFilter:Init()

    -- init client update dialog filter
    ClientUpdateDialogFilter:Init()

    -- init msg box filter
    MsgBoxFilter:Init()

    -- init on load block region filter
    OnWorldInitialRegionsLoadedFilter:Init()

    -- init world info filter
    WorldInfoFilter:Init()

    -- init local service world filter
    LocalServiceWorldFilter:Init()
end