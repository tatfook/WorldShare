--[[
Title: History Manager
Author(s):  big
Date: 2018.09.03
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local HistoryManager = NPL.load("(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua")
------------------------------------------------------------
]]
local Screen = commonlib.gettable("System.Windows.Screen")

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local MdParser = NPL.load("(gl)Mod/WorldShare/parser/MdParser.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")
local Bookmark = NPL.load("(gl)Mod/WorldShare/database/Bookmark.lua")

local HistoryManager = NPL.export()

HistoryManager.RecommendedWorldList = 'https://git.keepwork.com/gitlab_rls_official/keepworkdatasource/raw/master/official/paracraft/RecommendedWorldList.md'

function HistoryManager:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/HistoryManager/HistoryManager.html", "HistoryManager", 0, 0, "_fi", false)

    Screen:Connect("sizeChanged", HistoryManager, HistoryManager.OnScreenSizeChange, "UniqueConnection")
    HistoryManager.OnScreenSizeChange()

    params._page.OnClose = function()
        Store:remove('page/HistoryManager')
        Screen:Disconnect("sizeChanged", HistoryManager, HistoryManager.OnScreenSizeChange)
    end

    self:getRecommendedWorldList()
end

function HistoryManager:setPage()
    Store:set("page/HistoryManager", document:GetPageCtrl())
end

function HistoryManager.refreshPage()
    local HistoryManagerPage = Store:get('page/HistoryManager')

    if (HistoryManagerPage) then
        HistoryManagerPage:Refresh(0.01)
    end
end

function HistoryManager:closePage()
    local HistoryManagerPage = Store:get('page/HistoryManager')

    if (HistoryManagerPage) then
        HistoryManagerPage:CloseWindow()
    end
end

function HistoryManager.OnScreenSizeChange()
    local HistoryManagerPage = Store:get('page/HistoryManager')

    if (not HistoryManagerPage) then
        return false
    end

    local height = math.floor(Screen:GetHeight())

    local areaHeaderNode = HistoryManagerPage:GetNode("area_header")
    local marginLeft = math.floor((Screen:GetWidth() - 850) / 2)

    areaHeaderNode:SetCssStyle('margin-left', marginLeft)

    local areaContentNode = HistoryManagerPage:GetNode("area_content")


    areaContentNode:SetCssStyle('height', height - 47)
    areaContentNode:SetCssStyle('margin-left', marginLeft)

    local splitNode = HistoryManagerPage:GetNode("area_split")

    splitNode:SetCssStyle("height", height - 47)

    HistoryManager.refreshPage()
end

function HistoryManager:hasData()
    return true
end

function HistoryManager:getLocalRecommendedWorldList()
    local data = Utils:GetFileData('Mod/WorldShare/database/RecommendedWorldList.md')

    local tree, items = MdParser:MdToTable(data)

    return tree or {}, items or {}
end

function HistoryManager:getRemoteRecommendedWorldList(callback)
    HttpRequest:GetUrl(
        self.RecommendedWorldList,
        function (data, err)
            if (not data or type(data) ~= 'string') then
                return false
            end

            local tree, items = MdParser:MdToTable(data)

            if type(callback) == 'function' then
                callback(tree, items)
            end
        end
    )
end

function HistoryManager:mergeRecommendedWorldList(RemoteTree, RemoteItems)
    self:setRecommendKeyToItems(RemoteItems)

    local BookmarkTree, BookmarkItems = Bookmark:getBookmark()

    local mergeTree = self:mergeTree(RemoteTree, BookmarkTree)
    local mergeItems = self:mergeItems(RemoteItems, BookmarkItems)

    Bookmark:setBookmark(mergeTree, mergeItems)

    Store:set('user/historyTree', mergeTree)
    Store:set('user/historyItems', mergeItems)

    self:updateList()
    self.refreshPage()
end

-- It will be running when show page
function HistoryManager:getRecommendedWorldList()
    local LocalTree, LocalItems = self:getLocalRecommendedWorldList()
    local BookmarkTree, BookmarkItems = Bookmark:getBookmark()

    self:setRecommendKeyToItems(LocalItems)

    local mergeTree = self:mergeTree(LocalTree, BookmarkTree)
    local mergeItems = self:mergeItems(LocalItems, BookmarkItems)

    mergeTree['favorite'] = {
        displayName = L"收藏",
        name = 'favorite',
        type = 'category'
    }

    Bookmark:setBookmark(mergeTree, mergeItems)

    Store:set('user/historyTree', mergeTree)
    Store:set('user/historyItems', mergeItems)

    self:getRemoteRecommendedWorldList(
        function(RemoteTree, RemoteItems)
            self:mergeRecommendedWorldList(RemoteTree, RemoteItems)
        end
    )

    self:updateList()
    self.refreshPage()
end

-- set recommend key on items
function HistoryManager:setRecommendKeyToItems(items)
    if type(items) ~= 'table' then
        return false
    end

    for key, item in ipairs(items) do
        item['recommend'] = true
    end
end

function HistoryManager:mergeTree(target, source)
    if type(target) ~= 'table' or type(source) ~= 'table' then
        return false
    end

    local mergeList = commonlib.copy(target)

    for key, item in pairs(source) do
        if not mergeList[key] then
            mergeList[key] = item
        else
            if not Utils:IsEquivalent(mergeList[key], item) then
                local mergeItem = Utils:MergeTable(mergeList[key], item)

                mergeList[key] = mergeItem
            end
        end
    end

    return mergeList
end

function HistoryManager:mergeItems(target, source)
    local mergeItems = commonlib.copy(target)

    for sKey, sItem in ipairs(source) do
        local beExist = false

        for mKey, mItem in ipairs(mergeItems) do
            if mItem['displayName'] == sItem['displayName'] then
                beExist = true

                if not Utils:IsEquivalent(mItem, sItem) then
                    mergeItems[mKey] = Utils:MergeTable(mItem, sItem)
                end

                break
            end
        end

        if not beExist then
            mergeItems[#mergeItems + 1] = sItem
        end
    end

    return mergeItems
end

function HistoryManager:updateList()
    local tree = Store:get('user/historyTree')
    local items = Store:get('user/historyItems')
    local HistoryManagerPage = Store:get('page/HistoryManager')

    if type(tree) ~= 'table' or type(items) ~= 'table' then
        return false
    end

    items = self:filterItems(items) or items

    local treeList = self:sortTree(tree)
    local itemsList = self:sortItems(items)

    Store:set('user/historyTreeList', treeList)
    Store:set('user/historyItemsList', itemsList)

    HistoryManagerPage:GetNode("historyTree"):SetAttribute('DataSource', treeList)
    HistoryManagerPage:GetNode('historyItems'):SetAttribute('DataSource', itemsList)
end

function HistoryManager:filterItems(items)
    if not self.selectTagName or self.selectTagName == 'all' or type(items) ~= 'table' then
        return false
    end

    local filterItems = commonlib.Array:new()

    for key, item in ipairs(items) do
        if item and type(item.tag) == 'string' then
            local tagArray = commonlib.split(item.tag, ',')

            for tKey, tName in ipairs(tagArray) do
                if tName == self.selectTagName then
                    filterItems:push_back(item)
                end
            end
        end
    end

    return filterItems
end

function HistoryManager:sortTree(tree)
    if type(tree) ~= 'table' then
        return false
    end

    local treeList = commonlib.Array:new()

    for key, item in pairs(tree) do
        if key ~= 'all' then
            treeList:push_back(item)
        end
    end

    if tree['all'] then
        treeList:push_front(tree['all'])
    end

    return treeList
end

function HistoryManager:sortItems(items)
    if type(items) ~= 'table' then
        return false
    end

    local itemsListArray = commonlib.ArrayMap:new()

    local today = os.date("%Y%m%d", os.time())
    local yesterday = os.date("%Y%m%d", os.time() - 86400)

    itemsListArray:push(today, commonlib.Array:new())
    itemsListArray:push(yesterday, commonlib.Array:new())

    for key, item in ipairs(items) do
        if item['revision'] and item['displayName'] and item['date'] then
            if itemsListArray[item['date']] then
                itemsListArray[item['date']]:push_back(item)
            else
                itemsListArray:push(item['date'], commonlib.Array:new())
                itemsListArray[item['date']]:push_back(item)
            end
        end
    end

    local function sort(a, b)
        if tonumber(a) > tonumber(b) then
            return a
        end
    end

    itemsListArray:ksort(sort)

    local itemsList = commonlib.Array:new()

    for key, item in itemsListArray:pairs() do
        itemsList:push_back(
            {
                type = 'date',
                date = key
            }
        )

        if #item ~= 0 then
            for iKey, iItem in ipairs(item) do
                iItem['type'] = 'world'
                itemsList:push_back(iItem)
            end
        else
            itemsList:push_back(
                {
                    type = 'empty'
                }
            )
        end
    end

    return itemsList
end

function HistoryManager:getItemsItemByIndex(index)
    if type(index) ~= 'number' then
        return false
    end

    local itemsList = Store:get('user/historyItemsList')

    if not itemsList or
       not itemsList[index] or
       type(itemsList[index]['tag']) ~= 'string' or
       type(itemsList[index]['displayName']) ~= 'string'
    then
        return false
    end

    return itemsList[index]
end

function HistoryManager:collectItem(index)
    local curItem = self:getItemsItemByIndex(index)

    if not curItem then
        return false
    end

    if Bookmark:isTagExist(curItem['displayName'], Bookmark.tag.FAVORITE) then
        Bookmark:removeTag(curItem['displayName'], Bookmark.tag.FAVORITE)
    else
        Bookmark:setTag(curItem['displayName'], Bookmark.tag.FAVORITE)
    end

    self:updateList()
    self.refreshPage()
end

function HistoryManager:deleteItem(index)
    local itemsList = Store:get('user/historyItemsList')
    local BookmarkTree, BookmarkItems = Bookmark:getBookmark()

    local function handleDelete()
        local currentItem = itemsList[index]

        if type(currentItem) ~= 'table' then
            return false
        end

        for key, item in ipairs(BookmarkItems) do
            if item['displayName'] and currentItem['displayName'] then
                if currentItem['displayName'] == item['displayName'] then
                    for k=key, #BookmarkItems do
                        BookmarkItems[k] = BookmarkItems[k+1]
                    end
                    break
                end
            end
        end

        self:setBookmark(BookmarkTree, BookmarkItems)
        self:getRecommendedWorldList()
    end

    _guihelper.MessageBox(
        L"是否删除此记录？",
        function(res)
            if (res and res == 6) then
                handleDelete()
            end
        end
    )
end

function HistoryManager:selectCategory(index)
    local tree = Store:get('user/historyTreeList')

    if type(index) ~= 'number' or type(tree) ~= 'table' then
        return false
    end

    local curItem = tree[index]

    if not curItem or not curItem.name then
        return false
    end

    self.selectTagName = curItem.name

    self:updateList()
    self.refreshPage()
end

function HistoryManager.formatDate(date)
    if type(date) ~= 'string' then
        return false
    end

    local formatDate = ''

    local today = os.date("%Y%m%d", os.time())
    local yesterday = os.date("%Y%m%d", os.time() - 86400)

    if tonumber(date) == tonumber(today) then
        formatDate = format("%s-", L'今天')
    end

    if tonumber(date) == tonumber(yesterday) then
        formatDate = format("%s-", L'昨天')
    end

    local year = string.sub(date, 1, 4)
    local month = string.sub(date, 5, 6)
    local day = string.sub(date, 7, 8)

    return format("%s%s%s%s%s%s%s", formatDate, year or '', L"年", month or '', L"月", day or '', L"日")
end