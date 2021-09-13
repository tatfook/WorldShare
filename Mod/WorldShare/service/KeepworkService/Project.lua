--[[
Title: Keepwork Service Project
Author(s):  big
CreateDate: 2019.02.18
ModifyDate: 2021.09.01
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
------------------------------------------------------------
]]

local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local Encoding = commonlib.gettable('commonlib.Encoding')

-- service
local KeepworkServiceSession = NPL.load('./Session.lua')

-- api
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Projects.lua')
local KeepworkProjectStarApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/ProjectStar.lua')
local KeepworkWorldsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Worlds.lua')
local KeepworkMembersApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Members.lua')
local KeepworkAppliesApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Applies.lua')

local KeepworkServiceProject = NPL.export()

function KeepworkServiceProject:OnWorldLoad()
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if currentEnterWorld and currentEnterWorld.kpProjectId then
        self:Visit(currentEnterWorld.kpProjectId)
    end
end

-- This api will create a keepwork paracraft project and associated with paracraft world.
function KeepworkServiceProject:CreateProject(foldername, callback)
    if not KeepworkServiceSession:IsSignedIn() or not foldername then
        return false
    end

    KeepworkProjectsApi:CreateProject(foldername, callback, callback)
end

-- update projectinfo
function KeepworkServiceProject:UpdateProject(kpProjectId, params, callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    KeepworkProjectsApi:UpdateProject(kpProjectId, params, callback)
end

-- get projectinfo
function KeepworkServiceProject:GetProject(kpProjectId, callback, noTryStatus)
    KeepworkProjectsApi:GetProject(kpProjectId, callback, callback, noTryStatus)
end

-- get project members
function KeepworkServiceProject:GetMembers(pid, callback)
    KeepworkMembersApi:Members(pid, 5, -1, callback, callback)
end

-- add members
function KeepworkServiceProject:AddMembers(pid, users, callback)
    if not pid or type(users) ~= 'table' then
        return false
    end

    KeepworkMembersApi:Bulk(pid, 5, users, callback, callback)
end

-- handle apply
function KeepworkServiceProject:HandleApply(id, isAllow, callback)
    KeepworkAppliesApi:AppliesId(id, isAllow, callback, callback)
end

-- apply
function KeepworkServiceProject:Apply(message, callback)
    local userId = Mod.WorldShare.Store:Get('user/userId')

    if not userId then
        return false
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end

    KeepworkAppliesApi:PostApplies(currentWorld.kpProjectId, 5, 0, userId, message, callback, callback)
end

-- remove user from member
function KeepworkServiceProject:RemoveUserFromMember(id, callback)
    KeepworkMembersApi:DeleteMembersId(id, callback, callback)
end

-- get apply list
function KeepworkServiceProject:GetApplyList(pid, callback)
    KeepworkAppliesApi:Applies(pid, 5, 0, callback, callback)
end

-- get project id by worldname
function KeepworkServiceProject:GetProjectIdByWorldName(foldername, shared, callback)
    if type(callback) ~= 'function' then
        return false
    end

    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    local userId = tonumber(Mod.WorldShare.Store:Get('user/userId'))

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if type(data) ~= 'table' then
            return false
        end

        local bIsExist = false
        local world

        for key, item in ipairs(data) do
            if item.user and item.user.id == userId then
                -- remote world info mine
                if not shared then
                    bIsExist = true
                    world = item
                    break
                end
            else
                -- remote world info shared
                if shared then
                    bIsExist = true
                    world = tiem
                    break
                end
            end
        end

        if bIsExist then
            if type(world) ~= 'table' or not world.projectId then
                callback()
                return false
            end

            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
            currentWorld.kpProjectId = world.projectId
            Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    
            callback(world.projectId)
        else
            callback()
        end
    end)
end

function KeepworkServiceProject:GetProjectId()
    local urlKpProjectId = self:GetProjectFromUrlProtocol()
    if urlKpProjectId then
        return urlKpProjectId
    end

    local openKpProjectId = Mod.WorldShare.Store:Get('world/openKpProjectId')
    if openKpProjectId then
        return openKpProjectId
    end

    WorldCommon.LoadWorldTag()
    local tagInfo = WorldCommon.GetWorldInfo()

    if tagInfo and tagInfo.kpProjectId and tagInfo.kpProjectId ~= 0 then
        return tagInfo.kpProjectId
    end
end

function KeepworkServiceProject:GetProjectFromUrlProtocol()
    local cmdline = ParaEngine.GetAppCommandLine()
    local urlProtocol = string.match(cmdline or '', 'paracraft://(.*)$')
    urlProtocol = Encoding.url_decode(urlProtocol or '')

    local kpProjectId = urlProtocol:match('kpProjectId="([%S]+)"')

    if kpProjectId then
        return kpProjectId
    end
end

function KeepworkServiceProject:Visit(pid)
    KeepworkProjectsApi:Visit(pid)
end

-- remove a project
function KeepworkServiceProject:RemoveProject(kpProjectId, callback)
    if not kpProjectId then
        return false
    end

    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    KeepworkProjectsApi:RemoveProject(tonumber(kpProjectId), callback, callback)
end

function KeepworkServiceProject:GenerateMiniProgramCode(projectId, callback)
    if not callback or type(callback) ~= 'function' or not projectId then
        return false
    end

    KeepworkProjectsApi:ShareWxacode(
        tonumber(projectId),
        function(data, err)
            if err ~= 200 or not data or not data.wxacode then
                callback(false)
                return
            end

            callback(true, data.wxacode)
        end,
        function(data, err)
            callback(false)
        end
    )
end

-- get favorited projects
function KeepworkServiceProject:GetStaredProjects(projectIds, callback)
    KeepworkProjectStarApi:Search(projectIds, callback, callback)
end

-- judge project editable
-- true is editable, false is readonly
function KeepworkServiceProject:IsProjectReadOnly(pid, callback)
    if not KeepworkServiceSession:IsSignedIn() or
       not callback or
       type(callback) ~= 'function' then
        return
    end

    self:GetProject(pid, function(data, err)
        if data.level ~= 2 then
            callback(false, data.level)
        else
            callback(true, data.level)
        end
    end)
end