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
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local Bookmark = NPL.load("(gl)Mod/WorldShare/database/Bookmark.lua")
local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")

local HistoryManager = NPL.export()

function HistoryManager:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/HistoryManager/HistoryManager.html", "HistoryManager", 0, 0, "_fi", false)

    Screen:Connect("sizeChanged", HistoryManager, HistoryManager.OnScreenSizeChange, "UniqueConnection")
    HistoryManager.OnScreenSizeChange()

    params._page.OnClose = function()
        Store:Remove('page/HistoryManager')
        Screen:Disconnect("sizeChanged", HistoryManager, HistoryManager.OnScreenSizeChange)
    end

    self:GetWorldList()
end

function HistoryManager:SetPage()
    Store:Set("page/HistoryManager", document:GetPageCtrl())
end

function HistoryManager.Refresh()
    local HistoryManagerPage = Store:Get('page/HistoryManager')

    if (HistoryManagerPage) then
        HistoryManagerPage:Refresh(0.01)
    end
end

function HistoryManager:ClosePage()
    local HistoryManagerPage = Store:Get('page/HistoryManager')

    if (HistoryManagerPage) then
        HistoryManagerPage:CloseWindow()
    end
end

function HistoryManager.OnScreenSizeChange()
    local HistoryManagerPage = Store:Get('page/HistoryManager')

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

    HistoryManager.Refresh()
end

function HistoryManager:HasData()
    local historyItems = Store:Get("user/historyItems")

    -- echo(historyItems, true)

    return true
end

function HistoryManager:GetLocalRecommendedWorldList()
    local data = Utils:GetFileData('Mod/WorldShare/database/RecommendedWorldList.md')

    local tree, items = MdParser:MdToTable(data)

    return tree or {}, items or {}
end

function HistoryManager:GetRemoteRecommendedWorldList(callback)
    HttpRequest:GetUrl(
        Config.RecommendedWorldList,
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

function HistoryManager:MergeRecommendedWorldList(remoteTree, remoteItems)
    self:SetRecommendKeyToItems(remoteItems)

    local historyTree = Store:Get('user/historyTree')
    local historyItems = Store:Get('user/historyItems')

    local mergeTree = self:MergeTree(remoteTree, historyTree)
    local mergeItems = self:MergeItems(remoteItems, historyItems)

    Store:Set('user/historyTree', mergeTree)
    Store:Set('user/historyItems', mergeItems)

    self:UpdateList()
    self.Refresh()
end

-- It will be running when show page
function HistoryManager:GetWorldList()
    local localTree, localItems = self:GetLocalRecommendedWorldList()
    local bookmarkTree, bookmarkItems = Bookmark:GetBookmark()

    self:SetRecommendKeyToItems(localItems)

    local mergeTree = self:MergeTree(localTree, bookmarkTree)
    local mergeItems = self:MergeItems(localItems, bookmarkItems)

    mergeTree['favorite'] = {
        displayName = L"收藏",
        name = 'favorite',
        type = 'category'
    }

    Store:Set('user/historyTree', mergeTree)
    Store:Set('user/historyItems', mergeItems)

    self:GetRemoteRecommendedWorldList(
        function(remoteTree, remoteItems)
            self:MergeRecommendedWorldList(remoteTree, remoteItems)
        end
    )

    self:UpdateList()
    self.Refresh()
end

-- set recommend key on items
function HistoryManager:SetRecommendKeyToItems(items)
    if type(items) ~= 'table' then
        return false
    end

    for key, item in ipairs(items) do
        item['recommend'] = true
    end
end

function HistoryManager:MergeTree(target, source)
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

function HistoryManager:MergeItems(target, source)
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

function HistoryManager:UpdateList()
    local tree = Store:Get('user/historyTree')
    local items = Store:Get('user/historyItems')
    local HistoryManagerPage = Store:Get('page/HistoryManager')

    if type(tree) ~= 'table' or type(items) ~= 'table' then
        return false
    end

    items = self:FilterItems(items) or items

    local treeList = self:SortTree(tree)
    local itemsList = self:SortItems(items)

    Store:Set('user/historyTreeList', treeList)
    Store:Set('user/historyItemsList', itemsList)

    if not HistoryManagerPage then
        return false
    end

    HistoryManagerPage:GetNode("historyTree"):SetAttribute('DataSource', treeList)
    HistoryManagerPage:GetNode('historyItems'):SetAttribute('DataSource', itemsList)
end

function HistoryManager:FilterItems(items)
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

function HistoryManager:SortTree(tree)
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

function HistoryManager:SortItems(items)
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

function HistoryManager:GetItemsItemByIndex(index)
    if type(index) ~= 'number' then
        return false
    end

    local itemsList = Store:Get('user/historyItemsList')

    if not itemsList or
       not itemsList[index] or
       type(itemsList[index]['tag']) ~= 'string' or
       type(itemsList[index]['displayName']) ~= 'string'
    then
        return false
    end

    return itemsList[index]
end

function HistoryManager:CollectItem(index)
    local curItem = self:GetItemsItemByIndex(index)

    if not curItem or not curItem.displayName then
        return false
    end

    local displayName = curItem.displayName

    if not Bookmark:IsItemExist(displayName) then
        Bookmark:SetItem(displayName, curItem)
        Bookmark:SetTag(displayName, Bookmark.tag.FAVORITE)
    else
        if Bookmark:IsTagExist(displayName, Bookmark.tag.FAVORITE) then
            Bookmark:RemoveTag(displayName, Bookmark.tag.FAVORITE)
        else
            Bookmark:SetTag(displayName, Bookmark.tag.FAVORITE)
        end
    end

    self:UpdateList()
    self.Refresh()
end

function HistoryManager:DeleteItem(index)
    local itemsList = Store:Get('user/historyItemsList')

    _guihelper.MessageBox(
        L"是否删除此记录？",
        function(res)
            if (res and res == 6) then
                local currentItem = itemsList[index]

                if type(currentItem) ~= 'table' or not currentItem.displayName then
                    return false
                end

                Bookmark:RemoveItem(currentItem.displayName)

                self:GetWorldList()
            end
        end
    )
end

function HistoryManager:SelectCategory(index)
    local tree = Store:Get('user/historyTreeList')

    if type(index) ~= 'number' or type(tree) ~= 'table' then
        return false
    end

    local curItem = tree[index]

    if not curItem or not curItem.name then
        return false
    end

    self.selectTagName = curItem.name

    self:GetWorldList()
end

-- clear all local storage data
function HistoryManager:ClearHistory()
    local bookmarkTree, bookmarkItems = Bookmark:GetBookmark()
    Bookmark:SetBookmark(bookmarkTree, {})

    self:GetWorldList()
end

function HistoryManager.FormatDate(date)
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

function HistoryManager:OnWorldLoad()
    local curLesson = Store:Getter("lesson/GetCurLesson")
    local enterWorld = Store:Get("world/enterWorld")

    if curLesson then
        self:WriteLessonRecord(curLesson)
        return true
    end

    if enterWorld then
        self:WriteWorldRecord(enterWorld)
    end
end

function HistoryManager:WriteLessonRecord(curLesson)
    if not curLesson or not curLesson:GetName() then
        return false
    end

    local curData = {
        date = os.date("%Y%m%d", os.time()),
        displayName = curLesson:GetName(),
        revision = 0,
        tag = "",
        worldType="class" 
    }

    Bookmark:SetItem(displayName, curData)
end

function HistoryManager:WriteWorldRecord(enterWorld)
    if type(enterWorld) ~= "table" then
        return false
    end

    local curData

    if KeepworkService:IsSignedIn() then
        local username = Store:Get('user/username')

        curData = {
            author = username,
            date = os.date("%Y%m%d", os.time()),
            displayName = enterWorld.foldername,
            revision = enterWorld.revision,
            size = enterWorld.size,
            tag = "",
            worldType="world" 
        }
    else
        curData = {
            date = os.date("%Y%m%d", os.time()),
            displayName = enterWorld.foldername,
            revision = enterWorld.revision,
            size = enterWorld.size,
            tag = "",
            worldType="world" 
        }
    end

    local displayName = enterWorld.foldername

    if not displayName then
        return false
    end

    Bookmark:SetItem(displayName, curData)
end