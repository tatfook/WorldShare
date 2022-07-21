--[[
Title: Local Service History
Author(s): big
CreateDate: 2021.12.16
Place: Foshan
use the lib:
------------------------------------------------------------
local LocalServiceHistory = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceHistory.lua')
------------------------------------------------------------
]]

-- service
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')

-- database
local Bookmark = NPL.load('(gl)Mod/WorldShare/database/Bookmark.lua')

local LocalServiceHistory = NPL.export()

function LocalServiceHistory:LoadWorld(world)
    if world then
        self:WriteWorldRecord(world)
    end
end

function LocalServiceHistory:WriteWorldRecord(world)
    if not world or type(world) ~= 'table' then
        return
    end

    if world and
       type(world) == 'table' and
       world.kpProjectId then
        self:Visit(world.kpProjectId)
    end

    Bookmark:SetItem(world)
end

function LocalServiceHistory:GetWorldRecord()
    local bookmarkItems = Bookmark:GetBookmark()

    if not bookmarkItems or type(bookmarkItems) ~= 'table' then
        return {}
    end

    local items = {}

    for key, item in ipairs(bookmarkItems) do
        if item and
           type(item) == 'table' and
           item.projectId then
            items[#items + 1] = item
        end
    end

    return items
end

function LocalServiceHistory:Visit(projectId)
    KeepworkServiceProject:Visit(projectId)
end
