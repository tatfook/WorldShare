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
local KeepworkService = NPL.load("../KeepworkService.lua")

local KeepworkServiceProject = NPL.export()

function KeepworkServiceProject:Visit(projectId)
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
