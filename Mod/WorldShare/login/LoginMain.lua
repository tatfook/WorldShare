--[[
Title: login
Author(s):  big, minor refactor by LiXizhi
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
LoginMain.ShowPage()
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/main.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginUserinfo.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")

local WorldShare = commonlib.gettable("Mod.WorldShare")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")

local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")

LoginMain.LoginPage = nil
LoginMain.InfoPage = nil
LoginMain.ModalPage = nil
LoginMain.notFirstTimeShown = nil
LoginMain.current_type = 1
LoginMain.refreshing = nil

function LoginMain:ctor()
end

function LoginMain.init()
end

function LoginMain.ShowPage()
    local params = Utils:ShowWindow(850, 470, "Mod/WorldShare/login/LoginMain.html", "LoginMain")

    params._page.OnClose = function()
        LoginMain.LoginPage = nil
    end

    -- load last selected avatar if world is not loaded before.
    LoginUserInfo.OnChangeAvatar()

    if (not LoginUserInfo.IsSignedIn() and LoginUserInfo.LoginWithTokenApi()) then
        return
    end

    if (LoginMain.notFirstTimeShown) then
        LoginUserInfo.ignore_auto_login = true
    else
        LoginMain.notFirstTimeShown = true

        if (not LoginUserInfo.ignore_auto_login) then
            -- auto sign in here
            LoginUserInfo.checkDoAutoSignin(LoginMain.LoginPage)
        end
    end

    if (LoginUserInfo.hasExplicitLogin) then
        LoginUserInfo.getRememberPassword()
        LoginUserInfo.setSite()
    end

    LoginWorldList.RefreshCurrentServerList()
end

function LoginMain.showMessageInfo(msg)
    LoginMain.Msg = msg

    Utils:ShowWindow(500, 270, "Mod/WorldShare/login/Info.html", "Info", 300, 150)

    LoginMain.Msg = nil
end

function LoginMain.setLoginPage()
    LoginMain.LoginPage = document:GetPageCtrl()
    InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
    InternetLoadWorld.OnStaticInit()
    InternetLoadWorld.GetEvents():AddEventListener(
        "dataChanged",
        function(self, event)
            if (event.type_index == 1) then
                LoginMain.refreshPage()
            end
        end,
        nil,
        "LoginMain"
    )
end

function LoginMain.setPageRefreshing(status)
    LoginMain.refreshing = status and true or false
    LoginMain.refreshPage()
end

function LoginMain.showLoginModalImp(callback)
    if (LoginUserInfo.LoginWithTokenApi(callback)) then
        return
    end

    local params = Utils:ShowWindow(320, 350, "Mod/WorldShare/login/LoginModal.html", "LoginModal")

    params._page.OnClose = function()
        LoginMain.modalCall = nil
    end

    if (type(callback) == "function") then
        LoginMain.modalCall = callback
    end

    LoginUserInfo.getRememberPassword()
    LoginUserInfo.setSite()
    LoginUserInfo.autoLoginAction("modal")
end

function LoginMain.setInfoPage()
    if (LoginMain.InfoPage) then
        LoginMain.InfoPage:CloseWindow()
    end

    LoginMain.InfoPage = document:GetPageCtrl()
end

function LoginMain.setModalPage()
    LoginMain.ModalPage = document:GetPageCtrl()
end

function LoginMain.refreshPage(time)
    if (LoginMain.LoginPage) then
        LoginMain.LoginPage:Refresh(time or 0.01)
    end
end

function LoginMain.IsShowPage()
    if(LoginMain.LoginPage) then
        return true
    else
        return false
    end
end

function LoginMain.refreshModalPage(time)
    if (LoginMain.ModalPage) then
        LoginMain.ModalPage:Refresh(time or 0.01)
    end
end

function LoginMain.closeMessageInfo(delayTimeMs)
    commonlib.TimerManager.SetTimeout(
        function()
            if (LoginMain.InfoPage) then
                LoginMain.InfoPage:CloseWindow()
                LoginMain.InfoPage = nil
            end
        end,
        delayTimeMs or 500
    )
end

function LoginMain.closeModalPage()
    if(not LoginMain.ModalPage) then
        return false
    end

    LoginMain.ModalPage:CloseWindow()
end

function LoginMain.InputSearchContent()
    InternetLoadWorld.isSearching = true
    LoginMain.LoginPage:Refresh(0.1)
end

function LoginMain.ClosePage()
    if (LoginMain.IsMCVersion()) then
        InternetLoadWorld.ReturnLastStep()
    end
    if (LoginMain.LoginPage) then
        LoginMain.LoginPage:CloseWindow()
    end
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
    NPL.load("(gl)Mod/WorldShare/login/BrowseRemoteWorlds.lua")
    local BrowseRemoteWorlds = commonlib.gettable("Mod.WorldShare.login.BrowseRemoteWorlds")
    BrowseRemoteWorlds.ShowPage(
        function(bHasEnteredWorld)
            if (bHasEnteredWorld) then
                LoginMain.ClosePage()
            end
        end
    )
end