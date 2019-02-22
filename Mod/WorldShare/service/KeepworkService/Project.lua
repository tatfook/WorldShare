--[[
Title: KeepworkService Project
Author(s):  big
Date:  2019.02.18
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
------------------------------------------------------------
]]
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local KeepworkService = NPL.load("../KeepworkService.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local KeepworkServiceProject = NPL.export()

function KeepworkServiceProject:Visit(projectId)
    if not projectId then
        return false
    end

    local url = format("/projects/%d/visit", projectId)

    KeepworkService:Request(
        url,
        "GET",
        nil,
        nil,
        function(data, err)
        end
    )
end

function KeepworkServiceProject:GetProjectId()
    local tagInfo = WorldCommon.GetWorldInfo()
    local openKpProjectId = Store:Get('world/openKpProjectId')
    local urlKpProjectId = KeepworkService:GetProjectFromUrlProtocol()

    if tagInfo and tagInfo.kpProjectId then
        return tagInfo.kpProjectId
    end

    if urlKpProjectId then
        return urlKpProjectId
    end

    if openKpProjectId then
        return openKpProjectId
    end
end