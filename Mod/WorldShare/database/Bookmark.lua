--[[
Title: Bookmark
Author(s): big
CreateDate: 2018.09.30
ModifyDate: 2021.12.16
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Bookmark = NPL.load('(gl)Mod/WorldShare/database/Bookmark.lua')
------------------------------------------------------------
]]

local Bookmark = NPL.export()

function Bookmark:GetBookmark()
    local playerController = Mod.WorldShare.Store:Getter('user/GetPlayerController')

    if not playerController then
        playerController = GameLogic.GetPlayerController()
        local SetPlayerController = Mod.WorldShare.Store:Action('user/SetPlayerController')

        SetPlayerController(playerController)
    end

    return playerController:LoadLocalData('my_bookmark', {}, true)
end

function Bookmark:SetBookmark(items)
    if not items or type(items) ~= 'table' then
        return
    end

    local playerController = GameLogic.GetPlayerController()
    playerController:SaveLocalData('my_bookmark', items, true)
end

function Bookmark:GetItemByProjectId(id)
    if not id or type(id) ~= 'number' then
        return
    end

    local BookmarkItems = self:GetBookmark()

    if not BookmarkItems or type(BookmarkItems) ~= 'table' then
        return nil
    end

    for key, item in ipairs(BookmarkItems) do
        if item and
           item.projectId and
           item.projectId == id then
            return item
        end
    end
end

function Bookmark:GetItemByFoldername(foldername)
    if not foldername or type(foldername) ~= 'string' then
        return
    end

    local BookmarkItems = self:GetBookmark()

    if not BookmarkItems or type(BookmarkItems) ~= 'table' then
        return nil
    end

    for key, item in ipairs(BookmarkItems) do
        if item and
           item.foldername and
           item.foldername == foldername then
            return item
        end
    end
end

function Bookmark:SetItem(world)
    if not world or
       type(world) ~= 'table' or
       (not world.foldername and not world.kpProjectId) then
        return
    end

    local items = self:GetBookmark()
    local curData = {
        date = os.time(),
        foldername = world.foldername,
        name = world.name,
        projectId = world.kpProjectId,
    }

    local beExisted = false

    if curData.projectId then
        for key, item in ipairs(items) do
            if item and
               item.projectId and
               item.projectId == curData.projectId then
                items[key] = curData
                beExisted = true
                break
            end
        end
    else
        for key, item in ipairs(items) do
            if item and
               item.foldername and
               item.foldername == curData.foldername then
                items[key] = curData
                beExisted = true
                break
            end
        end
    end

    if not beExisted then
        items[#items + 1] = curData
    end

    self:SetBookmark(items)
end

function Bookmark:RemoveItemByProjectId(id)
    if not id or type(id) ~= 'number' then
        return
    end

    local items = self:GetBookmark()

    for key, item in ipairs(items) do
        if item and
           item.projectId and
           item.projectId == id then
            items[key] = nil
            break
        end
    end

    self:SetBookmark(items)
end

function Bookmark:RemoveItemByFoldername(foldername)
    if not id or type(foldername) ~= 'string' then
        return
    end

    local items = self:GetBookmark()

    for key, item in ipairs(items) do
        if item and
           item.foldername and
           item.foldername == foldername then
            items[key] = nil
            break
        end
    end

    self:SetBookmark(items)
end
