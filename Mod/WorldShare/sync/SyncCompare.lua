--[[
Title: SyncCompare
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")
NPL.load("(gl)script/ide/Encoding.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")
local Encoding = commonlib.gettable("commonlib.Encoding")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld")

local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")

local REMOTEBIGGER = "REMOTEBIGGER"
local TRYAGAIN = "TRYAGAIN"
local JUSTLOCAL = "JUSTLOCAL"
local JUSTREMOTE = "JUSTREMOTE"
local LOCALBIGGER = "LOCALBIGGER"
local EQUAL = "EQUAL"

function SyncCompare:syncCompare()
    local IsEnterWorld = GlobalStore.get("IsEnterWorld")
    local IsShowLoginPage = LoginMain.IsShowPage()

    SyncCompare:SetFinish(false)
    LoginMain.showMessageInfo(L "请稍后...")

    self:compareRevision(
        function(result)
            if (IsEnterWorld and not IsShowLoginPage) then
                local IsShareMode = GlobalStore.get("ShareMode")

                if(IsShareMode) then
                    ShareWorld:init()
                    LoginMain.closeMessageInfo()
                    return false
                end

                if (result == REMOTEBIGGER) then
                    SyncMain:StartSyncPage()
                elseif (result == TRYAGAIN) then
                    Utils.SetTimeOut(SyncCompare.syncCompare, 1000)
                end

                LoginMain.closeMessageInfo()
            else
                if (result == JUSTLOCAL) then
                    SyncMain.syncToDataSource()
                    LoginMain.closeMessageInfo()
                    return true
                end

                if (result == JUSTREMOTE) then
                    SyncMain:syncToLocal()
                    LoginMain.closeMessageInfo()
                    return true
                end

                if (result == REMOTEBIGGER or result == LOCALBIGGER or result == EQUAL) then
                    SyncMain:StartSyncPage()
                    LoginMain.closeMessageInfo()
                    return true
                end
            end
        end
    )
end

function SyncCompare:IsCompareFinish()
    return SyncCompare.compareFinish == true
end

function SyncCompare:SetFinish(value)
    SyncCompare.compareFinish = value
end

function SyncCompare:compareRevision(callback)
    local IsEnterWorld = GlobalStore.get("IsEnterWorld")
    local selectWorld = GlobalStore.get("selectWorld")

    if (selectWorld.status == 2) then
        if (type(callback) == "function") then
            callback(JUSTREMOTE)
            return true
        end
    end

    if (LoginUserInfo.IsSignedIn()) then
        if (selectWorld.is_zip) then
            _guihelper.MessageBox(L "不能同步ZIP文件")
            LoginMain.closeMessageInfo()
            return false
        end

        self:compare(callback)
    else
        LoginUserInfo.LoginWithTokenApi(
            function()
                self:compareRevision(callback)
            end
        )
    end
end

function SyncCompare:compare(callback)
    local IsEnterWorld = GlobalStore.get("IsEnterWorld")
    local foldername = GlobalStore.get("foldername")

    local worldDir = GlobalStore.get("worldDir")
    local remoteWorldsList = GlobalStore.get("remoteWorldsList")
    local remoteRevision = 0
    local currentRevision = WorldRevision:new():init(worldDir.default):Checkout()

    local localFiles = LocalService:new():LoadFiles(worldDir.default)
    local hasRevision = false

    GlobalStore.set("localFiles", localFiles)

    for key, value in ipairs(localFiles) do
        if (string.lower(value.filename) == "revision.xml") then
            hasRevision = true
            break
        end
    end

    if (hasRevision) then
        local function handleRevision(data, err)
            if (err == 0 or err == 502) then
                _guihelper.MessageBox(L "网络错误")
                return false
            end

            currentRevision = tonumber(currentRevision)
            currentRevision = (currentRevision == 0 or currentRevision == 1) and 0 or currentRevision
            remoteRevision = tonumber(data) or 0

            GlobalStore.set("currentRevision", currentRevision)
            GlobalStore.set("remoteRevision", remoteRevision)

            local result

            if (remoteRevision == 0) then
                result = JUSTLOCAL
            end

            if (currentRevision < remoteRevision) then
                result = REMOTEBIGGER
            end

            if (currentRevision > remoteRevision) then
                result = LOCALBIGGER
            end

            if (currentRevision == remoteRevision) then
                result = EQUAL
            end

            if (remoteRevision ~= 0) then
                local isWorldInRemoteLists = false

                for _, valueDistance in ipairs(remoteWorldsList) do
                    if (valueDistance["worldsName"] == foldername.utf8) then
                        isWorldInRemoteLists = true
                    end
                end

                if (not isWorldInRemoteLists) then
                    LoginMain.showMessageInfo(L "请稍后...")

                    SyncMain:RefreshKeepworkList(
                        function()
                            LoginWorldList.RefreshCurrentServerList(
                                function()
                                    SyncCompare.compareFinish = true
                                    LoginMain.closeMessageInfo()

                                    if (type(callback) == "function") then
                                        callback(TRYAGAIN)
                                    end
                                end
                            )
                        end
                    )

                    return false
                end
            end

            SyncCompare.compareFinish = true

            if (type(callback) == "function") then
                callback(result)
            end
        end

        GitService:new():getWorldRevision(foldername, handleRevision)
    else
        if (IsEnterWorld) then
            CommandManager:RunCommand("/save")

            SyncCompare:SetFinish(true)

            if (type(callback) == "function") then
                callback(TRYAGAIN)
            end
        else
            _guihelper.MessageBox(L "本地世界沒有版本信息")
            SyncCompare:SetFinish(true)

            if (type(callback) == "function") then
                callback()
            end

            return false
        end
    end
end
