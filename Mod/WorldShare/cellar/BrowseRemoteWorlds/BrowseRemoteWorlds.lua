--[[
Title: remote worlds
Author(s):  LiXizhi
Date: 2018/5/11
Desc: 
use the lib:
------------------------------------------------------------
local BrowseRemoteWorlds = NPL.load("(gl)Mod/WorldShare/login/BrowseRemoteWorlds.lua")
BrowseRemoteWorlds.ShowPage(callbackFunc)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");

local Screen = commonlib.gettable("System.Windows.Screen")
local Encoding = commonlib.gettable("commonlib.Encoding")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local SyncMain = NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

local BrowseRemoteWorlds = NPL.export()

BrowseRemoteWorlds.itemsPerLine = 3

function BrowseRemoteWorlds.Init()
    InternetLoadWorld.OnStaticInit()
    InternetLoadWorld.OnChangeType(2)
    Store:Set('page/BrowseRemoteWorlds', document:GetPageCtrl())

    InternetLoadWorld.GetEvents():AddEventListener(
        "dataChanged",
        function(self, event)
            if (event.type_index ~= 1) then
                BrowseRemoteWorlds.refreshPage()
            end
        end,
        nil,
        "BrowseRemoteWorlds"
    )
end

function BrowseRemoteWorlds.Refresh()
    local BrowseRemoteWorldsPage = Store:Get('page/BrowseRemoteWorlds')

    if (BrowseRemoteWorldsPage) then
        BrowseRemoteWorldsPage:Refresh()
    end
end

function BrowseRemoteWorlds.GetItemsPerLine()
    return BrowseRemoteWorlds.itemsPerLine
end

function BrowseRemoteWorlds.GetMarginLeft()
    return BrowseRemoteWorlds.margin_left
end

-- @param callbackFunc: callbackFunc(bHasEnteredWorld) end
function BrowseRemoteWorlds.ShowPage(callbackFunc)
    BrowseRemoteWorlds.callbackFunc = callbackFunc

    BrowseRemoteWorlds.OnScreenSizeChange()

    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/BrowseRemoteWorlds/BrowseRemoteWorlds.html", "BrowseRemoteWorlds", 0, 0, "_fi", false)

    Screen:Connect("sizeChanged", BrowseRemoteWorlds, BrowseRemoteWorlds.OnScreenSizeChange, "UniqueConnection")

    params._page.OnClose = function()
        Store:Remove('page/BrowseRemoteWorlds')
        InternetLoadWorld.OnChangeType(1)
        Screen:Disconnect("sizeChanged", BrowseRemoteWorlds, BrowseRemoteWorlds.OnScreenSizeChange)
    end

    BrowseRemoteWorlds.RefreshCurrentServerList()
end

function BrowseRemoteWorlds:OnScreenSizeChange()
    local item_width = 255
    BrowseRemoteWorlds.itemsPerLine = math.floor((Screen:GetWidth() - 50) / item_width)
    BrowseRemoteWorlds.margin_left = math.floor((Screen:GetWidth() - BrowseRemoteWorlds.itemsPerLine * item_width) / 2)
    BrowseRemoteWorlds.Refresh()
end

function BrowseRemoteWorlds.GetCurWorldInfo(info_type, world_index)
    local index = tonumber(world_index)
    local selected_world = InternetLoadWorld.cur_ds[world_index]

    if (selected_world) then
        if (info_type == "mode") then
            local mode = selected_world["world_mode"]

            if (mode == "edit") then
                return L"创作"
            else
                return L"参观"
            end
        else
            return selected_world[info_type]
        end
    end
end

function BrowseRemoteWorlds.OnClickBack()
    BrowseRemoteWorlds.ClosePage(false)
end

function BrowseRemoteWorlds.ClosePage(bHasEnteredWorld)
    local BrowseRemoteWorldsPage = Store:Get('page/BrowseRemoteWorlds')

    if (BrowseRemoteWorldsPage) then
        BrowseRemoteWorldsPage:CloseWindow()
    end

    if (BrowseRemoteWorlds.callbackFunc) then
        BrowseRemoteWorlds.callbackFunc(bHasEnteredWorld)
    end
end

function BrowseRemoteWorlds.RefreshCurrentServerList(callback)
    local BrowseRemoteWorldsPage = Store:Get('page/BrowseRemoteWorlds')

    if (BrowseRemoteWorldsPage) then
        local ServerPage = InternetLoadWorld.GetCurrentServerPage()

        if (not ServerPage.isFetching) then
            InternetLoadWorld.FetchServerPage(ServerPage)
        end

        BrowseRemoteWorlds.Refresh()
    end
end

function BrowseRemoteWorlds.EnterWorld(index)
    local index = tonumber(index)

    if (not index) then
        return false
    end

    InternetLoadWorld.selected_world_index = index

    local enterWorld = InternetLoadWorld.GetCurrentWorld()

    if not enterWorld then
        return false
    end

    enterWorld.is_zip = true

    Store:Set("world/enterWorld", enterWorld)
    InternetLoadWorld.EnterWorld(index)
end

function BrowseRemoteWorlds.DeleteWorld(index)
    local index = tonumber(index)

    if not index then
        return false
    end

    InternetLoadWorld.selected_world_index = index

    local selectWorld = InternetLoadWorld.GetCurrentWorld()
    local enterWorld = Store:Get('world/enterWorld')

    if (enterWorld) then
        if (enterWorld.foldername == selectWorld.foldername) then
            _guihelper.MessageBox(L"不能刪除正在编辑的世界")
            return
        end
    end

    InternetLoadWorld.DeleteSelectedWorld()
end
