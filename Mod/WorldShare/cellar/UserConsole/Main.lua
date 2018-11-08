--[[
Title: login
Author(s):  big, minor refactor by LiXizhi
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
------------------------------------------------------------
]]
local WorldShare = commonlib.gettable("Mod.WorldShare")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")

local UserInfo = NPL.load("./UserInfo.lua")
local WorldList = NPL.load("./WorldList.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local HistoryManager = NPL.load("(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local BrowseRemoteWorlds = NPL.load("(gl)Mod/WorldShare/cellar/BrowseRemoteWorlds/BrowseRemoteWorlds.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

local UserConsole = NPL.export()

function UserConsole.IsSignedIn()
   return KeepworkService:IsSignedIn()
end

-- this is called from ParaWorld Login App
function UserConsole:CheckShowUserWorlds()
    if(System.options.showUserWorldsOnce) then
        BrowseRemoteWorlds.ShowPage(
            function(bHasEnteredWorld)
                System.options.showUserWorldsOnce = nil;
                self:CloseUserConsole()
            end
        )
        return true;
    end
end

function UserConsole:ShowPage()
    if(self:CheckShowUserWorlds()) then
        return false
    end

    local params = Utils:ShowWindow(850, 470, "Mod/WorldShare/cellar/UserConsole/UserConsole.html", "UserConsole")

    params._page.OnClose = function()
        Store:Remove('page/UserConsole')
    end

    -- checkout wrong PWD
    KeepworkService:PWDValidation()

    -- load last selected avatar if world is not loaded before.
    UserInfo:OnChangeAvatar()

    if (not KeepworkService:IsSignedIn() and KeepworkService:LoginWithTokenApi(function() WorldList:RefreshCurrentServerList() end)) then
        return false
    end

    local notFirstTimeShown = Store:Get('user/notFirstTimeShown')

    if (notFirstTimeShown) then
        Store:Set('user/ignoreAutoLogin', true)
    else
        Store:Set('user/notFirstTimeShown', true)

        local ignoreAutoLogin = Store:Get('user/ignoreAutoLogin')

        if (not ignoreAutoLogin) then
            -- auto sign in here
            UserInfo:CheckDoAutoSignin()
        end
    end

    WorldList:RefreshCurrentServerList()
end

function UserConsole:SetPage()
    Store:Set('page/UserConsole', document:GetPageCtrl())

    InternetLoadWorld.OnStaticInit()
    InternetLoadWorld.GetEvents():AddEventListener(
        "dataChanged",
        function(that, event)
            if (event.type_index == 1) then
                self:Refresh()
            end
        end,
        nil,
        "UserConsole"
    )
end

function UserConsole:ClosePage()
    if (UserConsole.IsMCVersion()) then
        InternetLoadWorld.ReturnLastStep()
    end

    local UserConsolePage = Store:Get('page/UserConsole')

    if (UserConsolePage) then
        UserConsolePage:CloseWindow()
    end
end

function UserConsole:Refresh(time)
    UserConsolePage = Store:Get('page/UserConsole')

    if (UserConsolePage) then
        UserConsolePage:Refresh(time or 0.01)
    end
end

function UserConsole:IsShowUserConsole()
    if(Store:Get('page/UserConsole')) then
        return true
    else
        return false
    end
end

function UserConsole.InputSearchContent()
    InternetLoadWorld.isSearching = true

    local UserConsolePage = Store:Get('page/UserConsole')

    if (UserConsolePage) then
        UserConsolePage:Refresh(0.1)
    end
end

function UserConsole.IsMCVersion()
    if(System.options.mc) then
        return true;
    else
        return false;
    end
end

function UserConsole.OnImportWorld()
    ParaGlobal.ShellExecute("open", LocalLoadWorld.GetWorldFolderFullPath(), "", "", 1)
end

function UserConsole.OnClickOfficialWorlds()
    BrowseRemoteWorlds.ShowPage(
        function(bHasEnteredWorld)
            if (bHasEnteredWorld) then
                self:ClosePage()
            end
        end
    )
end

function UserConsole:CreateNewWorld()
    self:ClosePage()
    CreateWorld:CreateNewWorld()
end

function UserConsole:ShowHistoryManager()
    HistoryManager:ShowPage()
end