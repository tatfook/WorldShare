--[[
Title: share world to datasource
Author(s): big
Date: 2017.5.12
Desc:  It can take snapshot for the current world. It can quick save or full save the world to datasource. 
use the lib:
------------------------------------------------------------
local ShareWorld = NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua")
ShareWorld.ShowPage()
-------------------------------------------------------
]]
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local SyncCompare = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncCompare.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local LoginWorldList = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginWorldList.lua")

local ShareWorld = NPL.export()

function ShareWorld:init()
    Store:set("world/ShareMode", true)
    Store:set("world/worldDir", self:GetEnterWorldDir())
    Store:set("world/foldername", self:GetEnterFoldername())
    Store:set("world/selectWorld", self:GetEnterWorld())

    local enterWorld = self:GetEnterWorld()
    echo(enterWorld, true)
    if(not enterWorld or enterWorld.is_zip) then
        _guihelper.MessageBox(L"此世界不支持分享")
        return false
    end

    if (not LoginUserInfo.IsSignedIn()) then
        function syncCompare()
            SyncCompare:syncCompare()
        end

        if (not LoginUserInfo.checkDoAutoSignin(syncCompare)) then
            LoginMain.ShowLoginModalImp(syncCompare)
        end

        return false
    end

    if (not LoginUserInfo.CheckoutVerified()) then
        return false
    end

    SyncCompare:syncCompare()
end

function ShareWorld:ShowShareWorldImp()
    local params = Utils:ShowWindow(640, 415, "Mod/WorldShare/cellar/ShareWorld/ShareWorld.html", "ShareWorld")

    params._page.OnClose = function()
        Store:remove('page/ShareWorld')
    end

    local ShareWorldImp = Store:get('page/ShareWorld')
    local filepath = self:GetPreviewImagePath()

    if (ParaIO.DoesFileExist(filepath) and ShareWorldImp) then
        ShareWorldImp:SetNodeValue("ShareWorldImage", filepath)
    end

    self:refreshShareWorldImp()
end

function ShareWorld:GetEnterWorldDir()
    return Store:get("world/enterWorldDir")
end

function ShareWorld:GetEnterFoldername()
    return Store:get("world/enterFoldername")
end

function ShareWorld:GetEnterWorld()
    return Store:get("world/enterWorld")
end

function ShareWorld:GetPreviewImagePath()
    local worldDir = self:GetEnterWorldDir()

    return format("%spreview.jpg", worldDir.default)
end

function ShareWorld:setShareWorldImp()
    Store:set('page/ShareWorld', document:GetPageCtrl())
end

function ShareWorld:closeShareWorldImp()
    local ShareWorldImp = Store:get('page/ShareWorld')

    if (ShareWorldImp) then
        ShareWorldImp:CloseWindow()
    end
end

function ShareWorld:refreshShareWorldImp(times)
    local ShareWorldImp = Store:get('page/ShareWorld')

    if (ShareWorldImp) then
        ShareWorldImp:Refresh(times or 0.01)
    end
end

function ShareWorld:GetWorldSize()
    local tagInfor = WorldCommon.GetWorldInfo()

    return Utils.formatFileSize(tagInfor.size)
end

function ShareWorld:GetRemoteRevision()
    return tonumber(Store:get("world/remoteRevision")) or 0
end

function ShareWorld:GetCurrentRevision()
    return tonumber(Store:get("world/currentRevision")) or 0
end

function ShareWorld:shareNow()
    if (self:GetRemoteRevision() > self:GetCurrentRevision()) then
        _guihelper.MessageBox(
            L"当前本地版本小于远程版本，是否继续上传？",
            function(res)
                if (res and res == 6) then
                    SyncMain:syncToDataSource()
                    self:closeShareWorldImp()
                end
            end
        )

        return false
    end

    SyncMain:syncToDataSource()
    self:closeShareWorldImp()
end

function ShareWorld:snapshot()
    local ShareWorldImp = Store:get('page/ShareWorld')
    ShareWorldPage.TakeSharePageImage()
    self:UpdateImage(true)

    if (self:GetRemoteRevision() == self:GetCurrentRevision()) then
        CommandManager:RunCommand("/save")
        self:closeShareWorldImp()
        self:init()
    end
end

function ShareWorld:UpdateImage(bRefreshAsset)
    local ShareWorldPage = Store:get('page/ShareWorld')

    if (ShareWorldPage) then
        local filepath = self:GetPreviewImagePath()

        ShareWorldPage:SetUIValue("ShareWorldImage", filepath)

        if (bRefreshAsset) then
            ParaAsset.LoadTexture("", filepath, 1):UnloadAsset()
        end

        self:refreshShareWorldImp()
    end
end

function ShareWorld.getWorldUrl()
    if (not LoginUserInfo.IsSignedIn()) then
        return ""
    end

    local foldername = Store:get("world/foldername")
    local userinfo = Store:get("user/userinfo")

    return format("%s/%s/paracraft/%s", LoginUserInfo.site(), userinfo.username, foldername.utf8)
end

function ShareWorld.openWorldWebPage()
    if (not LoginUserInfo.IsSignedIn()) then
        return ""
    end

    local foldername = Store:get("world/foldername")
    local userinfo = Store:get("user/userinfo")

    local url = format("%s/%s/paracraft/%s", LoginUserInfo.site(), userinfo.username, foldername.default)
    ParaGlobal.ShellExecute("open", url, "", "", 1)
end