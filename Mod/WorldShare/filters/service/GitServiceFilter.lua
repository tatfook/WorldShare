--[[
Title: Get Service Filter
Author(s):  Big
Date: 2021.2.28
Desc: 
use the lib:
------------------------------------------------------------
local GitServiceFilter = NPL.load('(gl)Mod/WorldShare/filters/service/LocalService/GitServiceFilter.lua')
GitServiceFilter:Init()
------------------------------------------------------------
]]

-- service
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")

local GitServiceFilter = NPL.export()

function GitServiceFilter:Init()
    GameLogic.GetFilters():add_filter(
        'service.git_service.get_content_with_raw',
        function(foldername, username, path, commitId, callback, cdnState)
            GitService:GetContentWithRaw(foldername, username, path, commitId, callback, cdnState)
        end
    )
end