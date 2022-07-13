--[[
Title: Keepwork Projects API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectsApi.lua')
------------------------------------------------------------
]]
local Encoding = commonlib.gettable('commonlib.Encoding')

local KeepworkBaseApi = NPL.load('./BaseApi.lua')
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

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
        type = 1,
        privilege = 165,
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
    if not kpProjectId or
       type(kpProjectId) ~= 'number' or
       not params or
       type(params) ~= 'table' then
        return false
    end

    local url = format('/projects/%d', kpProjectId)

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

    local url = format('/projects/%d/detail', kpProjectId)

    KeepworkBaseApi:Get(url, nil, nil, success, error, noTryStatus)
end

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

    local url = format('/projects/%d/visit', kpProjectId)

    KeepworkBaseApi:Get(url, nil, nil, callback)
end

-- url: /projects/search
-- method: POST
-- params:
--[[
    { id: { $in : [1, 2, 3] } }
]]
-- return: object
function KeepworkProjectsApi:Search(xPerPage, xPage, params, success, error)
    local url = '/projects/search'

    if type(xPerPage) == 'number' then
        url = url .. '?x-per-page=' .. xPerPage

        if type(xPerPage) == 'number' then
            url = url .. '&x-page=' .. xPage
        end
    end

    KeepworkBaseApi:Post(url, params, nil, success, error)
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
-- method: DELETE
-- return: object
function KeepworkProjectsApi:RemoveProject(kpProjectId, password, success, error)
    if not kpProjectId or
       type(kpProjectId) ~= 'number' or
       not password or
       type(password) ~= 'string' then
        return
    end

    local url = format('/projects/%d', kpProjectId)
    local params = {
        password = password
    }

    KeepworkBaseApi:Delete(url, params, nil ,success, error)
end

-- url: /projects/shareWxacode
-- method: POST
-- params:
--[[
    projectId int necessary
]]
-- return: object
function KeepworkProjectsApi:ShareWxacode(projectId, success, error)
    if not projectId or type(projectId) ~= 'number' then
        return false
    end

    KeepworkBaseApi:Post('/projects/shareWxacode', { projectId = projectId }, nil, success, error)
end

-- url: /projects/queryByWorldNameAndUsername
-- method: POST
-- params:
--[[
    worldName string necessary
    username string necessary
]]
-- return: object
function KeepworkProjectsApi:QueryByWorldNameAndUsername(worldName, username, success, error)
    if not worldName or type(worldName) ~= 'string' or not username or type(username) ~= 'string' then
        return false
    end

    local parmas = {
        worldName = worldName,
        username = username
    }

    KeepworkBaseApi:Post('/projects/queryByWorldNameAndUsername', parmas, nil, success, error)
end

-- url: /projects/mySchools
-- method: GET
-- params:
--[[
    x-per-page int not necessary
    x-page int not necessary
]]
-- return: object
function KeepworkProjectsApi:MySchools(xPerPage, xPage, success, error)
    KeepworkBaseApi:Get('/projects/mySchools', nil, nil, success, error)
end

-- url: /projects/:id/leave
-- method: POST
-- params:
--[[
    id int necessary project id
]]
-- return: object
function KeepworkProjectsApi:Leave(pid, success, error)
    if not pid or type(pid) ~= 'number' then
        return
    end

    KeepworkBaseApi:Post(
        format('/projects/%d/leave', pid),
        nil,
        nil,
        success,
        error
    )
end
