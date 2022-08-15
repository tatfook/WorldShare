--[[
Title: Keepwork Users Api Filter
Author(s): big
CreateDate: 2022.8.11
Desc: 
use the lib:
------------------------------------------------------------
local KeepworkUsersApiFilter = NPL.load('(gl)Mod/WorldShare/filters/api/Keepwork/KeepworkUsersApiFilter.lua')
KeepworkUsersApiFilter:Init()
------------------------------------------------------------
]]

-- api
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkUsersApi.lua")

local KeepworkUsersApiFilter = NPL.export()

function KeepworkUsersApiFilter:Init()
    GameLogic.GetFilters():add_filter(
        'api.keepwork.users.parent_cellphone_captcha',
        function(...)
            KeepworkUsersApi:ParentCellphoneCaptcha(...)
        end
    )
end