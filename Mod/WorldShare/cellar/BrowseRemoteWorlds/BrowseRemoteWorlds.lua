--[[
Title: remote worlds
Author(s):  LiXizhi
Date: 2018/5/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/BrowseRemoteWorlds.lua");
local BrowseRemoteWorlds = commonlib.gettable("Mod.WorldShare.login.BrowseRemoteWorlds");
BrowseRemoteWorlds.ShowPage(callbackFunc)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local Screen = commonlib.gettable("System.Windows.Screen")
local Encoding = commonlib.gettable("commonlib.Encoding")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local SyncMain = NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local BrowseRemoteWorlds = NPL.export()

BrowseRemoteWorlds.itemsPerLine = 3

function BrowseRemoteWorlds.init()
    InternetLoadWorld.OnStaticInit()
    InternetLoadWorld.OnChangeType(2)
    Store:set('page/BrowseRemoteWorlds', document:GetPageCtrl())

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

function BrowseRemoteWorlds.refreshPage()
    local BrowseRemoteWorldsPage = Store:get('page/BrowseRemoteWorlds')

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

    local params = {
        url = "Mod/WorldShare/cellar/BrowseRemoteWorlds/BrowseRemoteWorlds.html",
        name = "BrowseRemoteWorlds",
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 0,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        directPosition = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params)

    Screen:Connect("sizeChanged", BrowseRemoteWorlds, BrowseRemoteWorlds.OnScreenSizeChange, "UniqueConnection")

    params._page.OnClose = function()
        Store:remove('page/BrowseRemoteWorlds')
        InternetLoadWorld.OnChangeType(1)
        Screen:Disconnect("sizeChanged", BrowseRemoteWorlds, BrowseRemoteWorlds.OnScreenSizeChange)
    end

    BrowseRemoteWorlds.RefreshCurrentServerList()
end

function BrowseRemoteWorlds:OnScreenSizeChange()
    local item_width = 255
    BrowseRemoteWorlds.itemsPerLine = math.floor((Screen:GetWidth() - 50) / item_width)
    BrowseRemoteWorlds.margin_left = math.floor((Screen:GetWidth() - BrowseRemoteWorlds.itemsPerLine * item_width) / 2)
    BrowseRemoteWorlds.refreshPage()
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
    local BrowseRemoteWorldsPage = Store:get('page/BrowseRemoteWorlds')

    if (BrowseRemoteWorldsPage) then
        BrowseRemoteWorldsPage:CloseWindow()
    end

    if (BrowseRemoteWorlds.callbackFunc) then
        BrowseRemoteWorlds.callbackFunc(bHasEnteredWorld)
    end
end

function BrowseRemoteWorlds.RefreshCurrentServerList(callback)
    local BrowseRemoteWorldsPage = Store:get('page/BrowseRemoteWorlds')

    if (BrowseRemoteWorldsPage) then
        local ServerPage = InternetLoadWorld.GetCurrentServerPage()

        if (not ServerPage.isFetching) then
            InternetLoadWorld.FetchServerPage(ServerPage)
        end

        BrowseRemoteWorlds.refreshPage()
    end
end

function BrowseRemoteWorlds.enterWorld(index)
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

    Store:set("world/enterWorld", enterWorld)
    InternetLoadWorld.EnterWorld(index)
end

function BrowseRemoteWorlds.deleteWorld(index)
    local index = tonumber(index)

    if not index then
        return false
    end

    InternetLoadWorld.selected_world_index = index

    local selectWorld = InternetLoadWorld.GetCurrentWorld()
    local enterWorld = Store:get('world/enterWorld')

    if (enterWorld) then
        if (enterWorld.foldername == selectWorld.foldername) then
            _guihelper.MessageBox(L"不能刪除正在编辑的世界")
            return
        end
    end

    InternetLoadWorld.DeleteSelectedWorld()
end
