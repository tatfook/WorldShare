--[[
Title: SyncCompare
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
local SyncCompare = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncCompare.lua")
------------------------------------------------------------
]]
local Encoding = commonlib.gettable("commonlib.Encoding")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local SyncMain = NPL.load("./SyncMain.lua")
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
local LoginWorldList = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginWorldList.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local SyncCompare = NPL.export()

local REMOTEBIGGER = "REMOTEBIGGER"
local TRYAGAIN = "TRYAGAIN"
local JUSTLOCAL = "JUSTLOCAL"
local JUSTREMOTE = "JUSTREMOTE"
local LOCALBIGGER = "LOCALBIGGER"
local EQUAL = "EQUAL"

function SyncCompare:syncCompare()
    if (not LoginUserInfo.IsSignedIn() or not LoginUserInfo.CheckoutVerified()) then
        return false
    end

    local IsEnterWorld = Store:get("world/IsEnterWorld")
    local isShowLoginMainPage = LoginMain.isShowLoginMainPage()

    self:SetFinish(false)

    Utils.SetTimeOut(
        function()
            if not self:IsCompareFinish() then
                MsgBox:Show(L"请稍后...")
            end
        end,
        500
    )

    self:compareRevision(
        function(result)
            if (IsEnterWorld and not isShowLoginMainPage) then
                local IsShareMode = Store:get("world/ShareMode")

                if (IsShareMode) then
                    ShareWorld:ShowShareWorldImp()
                    MsgBox:Close()
                    return false
                end

                if (result == REMOTEBIGGER) then
                    SyncMain:ShowStartSyncPage()
                elseif (result == TRYAGAIN) then
                    Utils.SetTimeOut(SyncCompare.syncCompare, 1000)
                end

                MsgBox:Close()
            else
                if (result == JUSTLOCAL) then
                    SyncMain:syncToDataSource()
                    MsgBox:Close()
                    return true
                end

                if (result == JUSTREMOTE) then
                    SyncMain:syncToLocal()
                    MsgBox:Close()
                    return true
                end

                if (result == REMOTEBIGGER or result == LOCALBIGGER or result == EQUAL) then
                    SyncMain:ShowStartSyncPage()
                    MsgBox:Close()
                    return true
                end
            end
        end
    )
end

function SyncCompare:IsCompareFinish()
    local compareFinish = Store:get('world/compareFinish')

    return compareFinish == true
end

function SyncCompare:SetFinish(value)
    Store:set('world/compareFinish', value)
end

function SyncCompare:compareRevision(callback)
    local IsEnterWorld = Store:get("world/IsEnterWorld")
    local selectWorld = Store:get("world/selectWorld")

    if (selectWorld and selectWorld.status == 2) then
        if (type(callback) == "function") then
            callback(JUSTREMOTE)
            return true
        end
    end

    if (LoginUserInfo.IsSignedIn()) then
        if (selectWorld.is_zip) then
            MsgBox:Close()
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
    local IsEnterWorld = Store:get("world/IsEnterWorld")
    local foldername = Store:get("world/foldername")

    local worldDir = Store:get("world/worldDir")
    local remoteWorldsList = Store:get("world/remoteWorldsList")
    local remoteRevision = 0

    local currentRevision = WorldRevision:new():init(worldDir.default):Checkout()

    if (not worldDir) then
        return false
    end

    if (self:HasRevision()) then
        local function handleRevision(data, err)
            if (err == 0 or err == 502) then
                _guihelper.MessageBox(L"网络错误")
                return false
            end

            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            Store:set("world/currentRevision", currentRevision)
            Store:set("world/remoteRevision", remoteRevision)

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

            self:SetFinish(true)

            if (type(callback) == "function") then
                callback(result)
            end
        end

        GitService:getWorldRevision(foldername, handleRevision)
    else
        _guihelper.MessageBox(L"本地世界沒有版本信息")
        self:SetFinish(true)
        MsgBox:Close()

        if (type(callback) == "function") then
            callback()
        end

        return false
    end
end

function SyncCompare:HasRevision()
    local worldDir = Store:get("world/worldDir")

    if (not worldDir or not worldDir.default) then
        return false
    end

    local localFiles = LocalService:LoadFiles(worldDir.default)
    local hasRevision = false

    Store:set("world/localFiles", localFiles)

    for key, file in ipairs(localFiles) do
        if (string.lower(file.filename) == "revision.xml") then
            hasRevision = true
            break
        end
    end

    return hasRevision
end
