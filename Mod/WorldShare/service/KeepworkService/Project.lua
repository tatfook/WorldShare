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
local Encoding = commonlib.gettable("commonlib.Encoding")

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
    local urlKpProjectId = self:GetProjectFromUrlProtocol()
    if urlKpProjectId then
        return urlKpProjectId
    end
    
    local openKpProjectId = Store:Get('world/openKpProjectId')
    if openKpProjectId then
        return openKpProjectId
    end

    local tagInfo = WorldCommon.GetWorldInfo()
    if tagInfo and tagInfo.kpProjectId then
        return tagInfo.kpProjectId
    end
end

function KeepworkServiceProject:GetProjectFromUrlProtocol()
    local cmdline = ParaEngine.GetAppCommandLine()
    local urlProtocol = string.match(cmdline or "", "paracraft://(.*)$")
    urlProtocol = Encoding.url_decode(urlProtocol or "")

    local kpProjectId = urlProtocol:match('kpProjectId="([%S]+)"')

    if kpProjectId then
        return kpProjectId
    end
end