--[[
Title: Keepwork Projects API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkProjectsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Projects.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local Projects = NPL.export()

-- url: /projects/searchForParacraft
-- method: POST
-- params:
--[[
    tagIds	integer [] 必须 标签的ID	
    item 类型: integer
    sortTag	integer	非必须 要排序的标签ID	
    projectId	integer	非必须 要搜索的项目ID
]]
-- return: object
function Projects:SearchForParacraft(xPerPage, xPage, params, callback)
    local url = '/projects/searchForParacraft'

    if type(xPerPage) == 'number' then
        url = url .. '?x-per-page=' .. xPerPage

        if type(xPerPage) == 'number' then
            url = url .. '&x-page=' .. xPage
        end
    end

    KeepworkBaseApi:Post(url, params, nil, callback)
end