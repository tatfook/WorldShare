--[[
Title: Bookmark
Author(s):  big
Date: 2018.09.30
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Bookmark = NPL.load("(gl)Mod/WorldShare/database/Bookmark.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local Bookmark = NPL.export()

Bookmark.tag = {
    FAVORITE = "favorite"
}

function Bookmark:GetBookmark()
    local playerController = Store:Getter("user/GetPlayerController")

    if not playerController then
        playerController = GameLogic.GetPlayerController()
        local SetPlayerController = Store:Action("user/SetPlayerController")

        SetPlayerController(playerController)
    end

    local bookmark = playerController:LoadLocalData("bookmark", nil, true)

    if type(bookmark) ~= "table" then
        return {}, {}
    end

    local tree
    local items

    if type(bookmark["tree"]) == "table" then
        tree = bookmark["tree"]
    end

    if type(bookmark["items"] == "table") then
        items = bookmark["items"]
    end

    return tree or {}, items or {}
end

function Bookmark:SetBookmark(tree, items)
    if type(tree) ~= "table" or type(items) ~= "table" then
        return false
    end

    local playerController = GameLogic.GetPlayerController()

    local list = {
        tree = tree,
        items = items
    }

    playerController:SaveLocalData("bookmark", list, true)
end

function Bookmark:GetItem(displayName)
    if type(displayName) ~= "string" then
        return false
    end

    local BookmarkTree, BookmarkItems = self:GetBookmark()

    if type(BookmarkItems) ~= "table" then
        return false
    end

    for key, item in ipairs(BookmarkItems) do
        if item and item.displayName and item.displayName == displayName then
            return item
        end
    end

    return false
end

function Bookmark:SetItem(displayName, curItem)
    local tree, items = self:GetBookmark()

    if type(curItem) ~= "table" and not curItem.displayName then
        return false
    end

    items = commonlib.Array:new(items)

    for key, item in ipairs(items) do
        if item and item.displayName and item.displayName == curItem.displayName then
            items:remove(key)
            break
        end
    end

    items:push_back(curItem)

    self:SetBookmark(tree, items)
end

function Bookmark:RemoveItem(displayName)
    local tree, items = self:GetBookmark()

    if type(displayName) ~= "string" then
        return false
    end

    for key, item in ipairs(items) do
        if item['displayName'] and displayName then
            if item['displayName'] == displayName then
                for k=key, #items do
                    items[k] = items[k+1]
                end
                break
            end
        end
    end

    self:SetBookmark(tree, items)
end

function Bookmark:SetTag(displayName, tagName)
    if type(displayName) ~= "string" or type(tagName) ~= "string" then
        return false
    end

    local curItem = self:GetItem(displayName)

    if not curItem then
        return false
    end

    local tagArray = commonlib.Array:new(commonlib.split(curItem["tag"] or "", ","))

    local tagBeExist = false

    for key, item in ipairs(tagArray) do
        if item == tagName then
            tagArray:remove(key)
            tagBeExist = true
            break
        end
    end

    if not tagBeExist then
        -- add
        tagArray:push_back(tagName)
    end

    curItem["tag"] = Mod.WorldShare.Utils.Implode(",", tagArray)

    self:SetItem(displayName, curItem)
end

function Bookmark:RemoveTag(displayName, tagName)
    if type(displayName) ~= "string" or type(tagName) ~= "string" then
        return false
    end

    local curItem = self:GetItem(displayName)

    if not curItem then
        return false
    end

    local tagArray = commonlib.Array:new(commonlib.split(curItem["tag"] or "", ","))

    for key, item in ipairs(tagArray) do
        if item == tagName then
            tagArray:remove(key)
            break
        end
    end

    curItem["tag"] = Mod.WorldShare.Utils.Implode(",", tagArray)

    self:SetItem(displayName, curItem)
end

function Bookmark:IsTagExist(displayName, tagName)
    if type(displayName) ~= "string" or type(tagName) ~= "string" then
        return false
    end

    local curItem = self:GetItem(displayName)

    if not curItem then
        return false
    end

    local tagArray = commonlib.Array:new(commonlib.split(curItem["tag"] or "", ","))

    local tagBeExist = false

    for key, item in ipairs(tagArray) do
        if item == tagName then
            tagBeExist = true
            break
        end
    end

    return tagBeExist
end

function Bookmark:IsItemExist(displayName)
    if type(displayName) ~= 'string' then
        return false
    end

    local curItem = self:GetItem(displayName)

    if not curItem then
        return false
    else
        return true
    end
end
