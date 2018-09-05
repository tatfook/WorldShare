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
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local HistoryManager = NPL.export()

HistoryManager.Menus = {
    {
        name = L"未分类"
    },
    {
        name = L"我的收藏"
    },
    {
        name = L"教学世界"
    }
}

function HistoryManager:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/HistoryManager/HistoryManager.html", "HistoryManager", 0, 0, "_fi", false)

    Screen:Connect("sizeChanged", HistoryManager, HistoryManager.OnScreenSizeChange, "UniqueConnection")
    HistoryManager.OnScreenSizeChange()

    params._page.OnClose = function()
        Store:remove('page/HistoryManager')
        Screen:Disconnect("sizeChanged", HistoryManager, HistoryManager.OnScreenSizeChange)
    end
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
