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
local HistoryManager = NPL.load("(gl)Mod/WorldShare/cellar/HistoryManager/HistoryManager.lua")
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

    local notFirstTimeShown = Store:get('user/notFirstTimeShown')

    if (notFirstTimeShown) then
        Store:set('user/ignoreAutoLogin', true)
    else
        Store:set('user/notFirstTimeShown', true)

        local ignoreAutoLogin = Store:get('user/ignoreAutoLogin')

        if (not ignoreAutoLogin) then
            -- auto sign in here
            LoginUserInfo.checkDoAutoSignin()
        end
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

function LoginMain.ShowLoginModalImp()
    if (LoginUserInfo.LoginWithTokenApi()) then
        return true
    end

    local params = Utils:ShowWindow(320, 350, "Mod/WorldShare/cellar/Login/LoginModal.html", "LoginModal")

    params._page.OnClose = function()
        Store:remove('page/LoginModal')
    end

    local LoginModalImp = Store:get('page/LoginModal')

    if not LoginModalImp then
        return false
    end

    local PWDInfo = LoginUserInfo.LoadSigninInfo()

    if (PWDInfo) then
        local rememberMeNode = LoginModalImp:GetNode('rememberPassword')
        local autoLoginNode = LoginModalImp:GetNode('autoLogin')

        rememberMeNode:SetAttribute('checked', 'checked')

        if PWDInfo and PWDInfo.autoLogin then
            autoLoginNode:SetAttribute('checked', 'checked')
        end

        LoginModalImp:SetValue('loginServer', PWDInfo.loginServer or '')
        LoginModalImp:SetValue('account', PWDInfo.account or '')
        LoginModalImp:SetValue('password', PWDInfo.password or '')
    end

    local registerUrl = format("%s/wiki/join", LoginUserInfo.site())

    LoginModalImp:GetNode('register'):SetAttribute('href', registerUrl)

    LoginMain.refreshLoginModalImp()
end

function LoginMain.setLoginModalImp()
    Store:set('page/LoginModal', document:GetPageCtrl())
end

function LoginMain.closeLoginModalImp()
    local LoginModalImp = Store:get('page/LoginModal')

    if(not LoginModalImp) then
        return false
    end

    LoginModalImp:CloseWindow()
end

function LoginMain.refreshLoginModalImp(time)
    local LoginModalImp = Store:get('page/LoginModal')

    if (LoginModalImp) then
        LoginModalImp:Refresh(time or 0.01)
    end
end

function LoginMain.InputSearchContent()
    InternetLoadWorld.isSearching = true

    local LoginMainPage = Store:get('page/LoginMain')

    if (LoginMainPage) then
        LoginMainPage:Refresh(0.1)
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
    BrowseRemoteWorlds.ShowPage(
        function(bHasEnteredWorld)
            if (bHasEnteredWorld) then
                LoginMain.ClosePage()
            end
        end
    )
end

function LoginMain:ShowHistoryManager()
    _guihelper.MessageBox(L"历史记录功能即将到来")
    -- HistoryManager:ShowPage()
end