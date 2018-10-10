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

local Bookmark = NPL.export()

Bookmark.tag = {
    FAVORITE = "favorite"
}

function Bookmark:getBookmark()
    local playerController = GameLogic.GetPlayerController()
    local bookmark = playerController:LoadLocalData("bookmark")

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

function Bookmark:setBookmark(tree, items)
    if type(tree) ~= "table" or type(items) ~= "table" then
        return false
    end

    local playerController = GameLogic.GetPlayerController()

    local list = {
        tree = tree,
        items = items
    }

    playerController:SaveLocalData("bookmark", list)
end

function Bookmark:getItem(displayName)
    if type(displayName) ~= "string" then
        return false
    end

    local BookmarkTree, BookmarkItems = self:getBookmark()

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

function Bookmark:setItem(displayName, curItem)
    local tree, items = self:getBookmark()

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

    self:setBookmark(tree, items)
end

function Bookmark:setTag(displayName, tagName)
    if type(displayName) ~= "string" or type(tagName) ~= "string" then
        return false
    end

    local curItem = self:getItem(displayName)

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

    curItem["tag"] = Utils:implode(",", tagArray)

    self:setItem(displayName, curItem)
end

function Bookmark:removeTag(displayName, tagName)
    if type(displayName) ~= "string" or type(tagName) ~= "string" then
        return false
    end

    local curItem = self:getItem(displayName)

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

    curItem["tag"] = Utils:implode(",", tagArray)

    self:setItem(displayName, curItem)
end

function Bookmark:isTagExist(displayName, tagName)
    if type(displayName) ~= "string" or type(tagName) ~= "string" then
        return false
    end

    local curItem = self:getItem(displayName)

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
