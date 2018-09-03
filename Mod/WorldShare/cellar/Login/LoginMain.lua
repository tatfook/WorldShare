--[[
Title: login
Author(s):  big, minor refactor by LiXizhi
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
LoginMain.ShowPage()
------------------------------------------------------------
]]
local WorldShare = commonlib.gettable("Mod.WorldShare")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")

local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
local LoginWorldList = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginWorldList.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local BrowseRemoteWorlds = NPL.load("(gl)Mod/WorldShare/cellar/BrowseRemoteWorlds/BrowseRemoteWorlds.lua")

local LoginMain = NPL.export()

function LoginMain:ctor()
end

function LoginMain.init()
end

-- this is called from ParaWorld Login App
function LoginMain:CheckShowUserWorlds()
    if(System.options.showUserWorldsOnce) then
        BrowseRemoteWorlds.ShowPage(
            function(bHasEnteredWorld)
                System.options.showUserWorldsOnce = nil;
                self.closeLoginMainPage()
            end
        )
        return true;
    end
end

function LoginMain:ShowLoginMainPage()
    if(self:CheckShowUserWorlds()) then
        return false
    end

    local params = Utils:ShowWindow(850, 470, "Mod/WorldShare/cellar/Login/LoginMain.html", "LoginMain")

    params._page.OnClose = function()
        Store:remove('page/LoginMain')
    end

    -- checkout wrong PWD
    LoginUserInfo.PWDValidation()

    -- load last selected avatar if world is not loaded before.
    LoginUserInfo.OnChangeAvatar()

    if (not LoginUserInfo.IsSignedIn() and LoginUserInfo.LoginWithTokenApi()) then
        return false
    end

    if (LoginMain.notFirstTimeShown) then
        LoginUserInfo.ignore_auto_login = true
    else
        LoginMain.notFirstTimeShown = true

        if (not LoginUserInfo.ignore_auto_login) then
            -- auto sign in here
            LoginUserInfo.checkDoAutoSignin()
        end
    end

    if (LoginUserInfo.hasExplicitLogin) then
        LoginUserInfo.getRememberPassword()
        LoginUserInfo.setSite()
    end

    LoginWorldList.RefreshCurrentServerList()
end

function LoginMain.setLoginMainPage()
    Store:set('page/LoginMain', document:GetPageCtrl())

    InternetLoadWorld.OnStaticInit()
    InternetLoadWorld.GetEvents():AddEventListener(
        "dataChanged",
        function(self, event)
            if (event.type_index == 1) then
                LoginMain.refreshLoginMainPage()
            end
        end,
        nil,
        "LoginMain"
    )
end

function LoginMain.closeLoginMainPage()
    if (LoginMain.IsMCVersion()) then
        InternetLoadWorld.ReturnLastStep()
    end

    local LoginMainPage = Store:get('page/LoginMain')

    if (LoginMainPage) then
        LoginMainPage:CloseWindow()
    end
end

function LoginMain.setLoginMainPageRefreshing(status)
    LoginMainPage = Store:get('page/LoginMain')

    if (not LoginMainPage) then
        return false
    end

    LoginMainPage.refreshing = status and true or false
    LoginMain.refreshLoginMainPage()
end

function LoginMain.refreshLoginMainPage(time)
    LoginMainPage = Store:get('page/LoginMain')

    if (LoginMainPage) then
        LoginMainPage:Refresh(time or 0.01)
    end
end

function LoginMain.isLoginMainPageRefreshing()
    LoginMainPage = Store:get('page/LoginMain')

    if (LoginMainPage and LoginMainPage.refreshing) then
        return true
    else
        return false
    end
end

function LoginMain.isShowLoginMainPage()
    if(Store:get('page/LoginMain')) then
        return true
    else
        return false
    end
end

function LoginMain.ShowLoginModalImp(callback)
    if (LoginUserInfo.LoginWithTokenApi(callback)) then
        return false
    end

    local params = Utils:ShowWindow(320, 350, "Mod/WorldShare/cellar/Login/LoginModal.html", "LoginModal")

    params._page.OnClose = function()
        Store:remove('page/LoginModal')
    end

    if (type(callback) == "function") then
        LoginMain.modalCall = callback
    end

    LoginUserInfo.getRememberPassword()
    LoginUserInfo.setSite()
    LoginUserInfo.autoLoginAction("modal")
end

function LoginMain.setLoginModalImp()
    Store:set('page/LoginModal', document:GetPageCtrl())
end

function LoginMain.closeLoginModalImp()
    local LoginModalPage = Store:get('page/LoginModal')

    if(not LoginModalPage) then
        return false
    end

    LoginModalPage:CloseWindow()
end

function LoginMain.refreshLoginModalImp(time)
    local LoginModalPage = Store:get('page/LoginModal')

    if (LoginModalPage) then
        LoginModalPage:Refresh(time or 0.01)
    end
end

function LoginMain.InputSearchContent()
    InternetLoadWorld.isSearching = true
    LoginMain.LoginPage:Refresh(0.1)
end

function LoginMain.IsMCVersion()
    if(System.options.mc) then
        return true;
    else
        return false;
    end
end

function LoginMain.OnImportWorld()
    ParaGlobal.ShellExecute("open", LocalLoadWorld.GetWorldFolderFullPath(), "", "", 1)
end

function LoginMain.OnClickOfficialWorlds()
    BrowseRemoteWorlds.ShowPage(
        function(bHasEnteredWorld)
            if (bHasEnteredWorld) then
                LoginMain.ClosePage()
            end
        end
    )
end