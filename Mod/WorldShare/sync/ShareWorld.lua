--[[
Title: share world to datasource
Author(s): big
Date: 2017.5.12
Desc:  It can take snapshot for the current world. It can quick save or full save the world to datasource. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua")
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld")
ShareWorld.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginUserInfo.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginUserInfo.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")

local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")

local ShareWorld = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.sync.ShareWorld"))

ShareWorld.SharePage = nil

function ShareWorld:ctor()
end

function ShareWorld.ShowPage()
    if (not LoginUserInfo.isVerified) then
        _guihelper.MessageBox(
            L "您需要到keepwork官网进行实名认证，认证成功后需重启paracraft即可正常操作，是否现在认证？",
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    ParaGlobal.ShellExecute("open", "http://keepwork.com/wiki/user_center", "", "", 1)
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )

        return
    end

    if (not LoginUserInfo.IsSignedIn()) then
        LoginMain.showLoginModalImp(
            function()
                ShareWorldPage.ShowPage()
            end
        )

        return false
    end

    SyncCompare:compare(
        function()
            ShareWorld:init()
        end
    )
end

function ShareWorld.ShowPageImp()
    Utils:ShowWindow(640, 415, "Mod/WorldShare/sync/ShareWorld.html", "ShareWorld")
end

function ShareWorld:init()
    ShareWorld.ShowPageImp()

    local worldDir = GlobalStore.get("worldDir")
    local filepath = format("%spreview.jpg", worldDir.default)

    if (ParaIO.DoesFileExist(filepath) and ShareWorld.SharePage) then
        ShareWorld.SharePage:SetNodeValue("ShareWorldImage", filepath)
    end

    ShareWorld.RefreshPage()
end

function ShareWorld.setSharePage()
    ShareWorld.SharePage = document:GetPageCtrl()
end

function ShareWorld.closeSharePage()
    ShareWorld.SharePage:CloseWindow()
end

function ShareWorld.RefreshPage(times)
    if (ShareWorld.SharePage) then
        ShareWorld.SharePage:Refresh(times or 0.01)
    end
end

function ShareWorld.GetFoldername()
    local foldername = GlobalStore.get("foldername")

    return foldername.utf8
end

function ShareWorld.GetWorldSize()
    local tagInfor = WorldCommon.GetWorldInfo()

    return Utils.formatFileSize(tagInfor.size)
end

function ShareWorld.GetRemoteRevision()
    local remoteRevision = GlobalStore.get("remoteRevision")

    return remoteRevision
end

function ShareWorld.GetCurrentRevision()
    local currentRevision = GlobalStore.get("currentRevision")

    return currentRevision
end

function ShareWorld.shareNow()
    if (ShareWorld.GetRemoteRevision() > ShareWorld.GetCurrentRevision()) then
        _guihelper.MessageBox(
            L "当前本地版本小于远程版本，是否继续上传？",
            function(res)
                if (res and res == 6) then
                    SyncMain:syncToDataSource()
                    ShareWorld.closeSharePage()
                end
            end
        )

        return true
    end

    SyncMain:syncToDataSource()
    ShareWorld.closeSharePage()
end

function ShareWorld.snapshot()
    ShareWorldPage.TakeSharePageImage()
    ShareWorld.UpdateImage(true)

    if (SyncMain.remoteRevison == SyncMain.currentRevison) then
        CommandManager:RunCommand("/save")
        ShareWorld.SharePage:CloseWindow()
        ShareWorld.ShowPage()
    end
end

function ShareWorld.UpdateImage(bRefreshAsset)
    if (ShareWorld.SharePage) then
        local filepath = ShareWorldPage.GetPreviewImagePath()
        ShareWorld.SharePage:SetUIValue("ShareWorldImage", filepath)
        if (bRefreshAsset) then
            ParaAsset.LoadTexture("", filepath, 1):UnloadAsset()
        end
    end
end

function ShareWorld.getWorldUrl()
    if (not LoginUserInfo.IsSignedIn()) then
        return ""
    end

    local foldername = GlobalStore.get("foldername")
    local userinfo = GlobalStore.get("userinfo")

    return format("%s/%s/paracraft/%s", LoginUserInfo.site, userinfo.username, foldername.utf8)
end

function ShareWorld.openWorldWebPage()
    if (not LoginUserInfo.IsSignedIn()) then
        return ""
    end

    local foldername = GlobalStore.get("foldername")
    local userinfo = GlobalStore.get("userinfo")

    local url = format("%s/%s/paracraft/%s", LoginUserInfo.site, userinfo.username, foldername.default)
    ParaGlobal.ShellExecute("open", url, "", "", 1)
end
