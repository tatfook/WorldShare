--[[
Title: Keepwork Project Star API
Author(s):  big
Date:  2020.12.17
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkProjectStarApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/ProjectStar.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkProjectStarApi = NPL.export()

-- url: /projectStars/search
-- method: POST
-- params:
--[[
    {
        "projectId": {
            "$in": [1,2,3...]
        },
        "userId": 1
    }
]]
-- return: object
function KeepworkProjectStarApi:Search(projectIds, success, error)
    local userId = Mod.WorldShare.Store:Get('user/userId')

    if not userId then
        return
    end

    local params = {
        projectId = {
            ['$in'] = projectIds
        },
        userId = userId,
        createdAt = {
            ['$gt'] = os.date('%Y-%m-%d', os.time())
        }
    }

    KeepworkBaseApi:Post('/projectStars/search', params, nil, success, error)
end