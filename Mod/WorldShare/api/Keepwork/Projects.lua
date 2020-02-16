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
local Encoding = commonlib.gettable("commonlib.Encoding")

local KeepworkBaseApi = NPL.load('./BaseApi.lua')
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")

local KeepworkProjectsApi = NPL.export()

-- url: /projects
-- method: POST
-- params:
--[[
]]
-- return: object
function KeepworkProjectsApi:CreateProject(foldername, success, error)
    local url = '/projects'

    local params = {
        name = foldername or '',
        type = 1
    }

    KeepworkBaseApi:Post(url, params, nil, success, error)
end

-- url: /projects/%d
-- method: PUT
-- params:
--[[
]]
-- return: object
function KeepworkProjectsApi:UpdateProject(kpProjectId, params, success, error)
    if type(kpProjectId) ~= 'number' or type(params) ~= 'table' then
        return false
    end

    local url = format("/projects/%d", kpProjectId)

    KeepworkBaseApi:Put(url, params, nil, success, error)
end

-- url: /projects/%d/detail
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkProjectsApi:GetProject(kpProjectId, success, error, noTryStatus)
    kpProjectId = tonumber(kpProjectId)
    if type(kpProjectId) ~= 'number' or kpProjectId == 0 then
        return false
    end

    local url = format("/projects/%d/detail", kpProjectId)

    KeepworkBaseApi:Get(url, nil, nil, success, error, noTryStatus)
end

-- -- url: 
-- function KeepworkProjectsApi:GetProjectByWorldName(foldername, success, error)
--     if type(foldername) ~= 'string' then
--         return false
--     end

--     local url = format("/worlds?worldName=%s", Encoding.url_encode(foldername or ''))

--     KeepworkBaseApi:Get(
--         url,
--         nil,
--         nil,
--         function(data, err)
--             if type(data) == 'table' then
--                 if type(success) == 'function' then
--                     success(data, err)
--                 end
--             else
--                 if type(error) == 'function' then
--                     error()
--                 end
--             end
--         end,
--         error
--     )
-- end

-- url: /projects/%d/visit
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkProjectsApi:Visit(kpProjectId, callback)
    if type(kpProjectId) ~= 'number' or kpProjectId == 0 then
        return false
    end

    local url = format("/projects/%d/visit", kpProjectId)

    KeepworkBaseApi:Get(url, nil, nil, callback)
end

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
function KeepworkProjectsApi:SearchForParacraft(xPerPage, xPage, params, success, error)
    local url = '/projects/searchForParacraft'

    if type(xPerPage) == 'number' then
        url = url .. '?x-per-page=' .. xPerPage

        if type(xPerPage) == 'number' then
            url = url .. '&x-page=' .. xPage
        end
    end

    KeepworkBaseApi:Post(url, params, nil, success, error)
end

-- url: /projects/%d
-- method: DELTE
-- return: object
function KeepworkProjectsApi:RemoveProject(kpProjectId, success, error)
    if type(kpProjectId) ~= 'number' then
        return false
    end

    local url = format("/projects/%d", kpProjectId)

    KeepworkBaseApi:Delete(url, nil, nil ,success, error)
end