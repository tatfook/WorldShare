--[[
Title: Compare
Author(s): big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
------------------------------------------------------------
]]
local Encoding = commonlib.gettable("commonlib.Encoding")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local Compare = NPL.export()

local REMOTEBIGGER = "REMOTEBIGGER"
local JUSTLOCAL = "JUSTLOCAL"
local JUSTREMOTE = "JUSTREMOTE"
local LOCALBIGGER = "LOCALBIGGER"
local EQUAL = "EQUAL"

function Compare:Init()
    if (not UserInfo.IsSignedIn() or not UserInfo:CheckoutVerified()) then
        return false
    end

    local isEnterWorld = Store:Get("world/isEnterWorld")
    local isShowUserConsolePage = UserConsole:IsShowUserConsole()

    self:SetFinish(false)

    Utils.SetTimeOut(
        function()
            if not self:IsCompareFinish() then
                MsgBox:Show(L"请稍后...")
            end
        end,
        500
    )

    self:GetCompareResult(
        function(result)
            if (isEnterWorld and not isShowUserConsolePage) then
                local isShareMode = Store:Get("world/shareMode")

                if (isShareMode) then
                    ShareWorld:ShowPage()
                    MsgBox:Close()
                    return false
                end

                if (result == REMOTEBIGGER) then
                    SyncMain:ShowStartSyncPage()
                end

                MsgBox:Close()
            else
                if (result == JUSTLOCAL) then
                    SyncMain:SyncToDataSource()
                    MsgBox:Close()
                    return true
                end

                if (result == JUSTREMOTE) then
                    SyncMain:SyncToLocal()
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

function Compare:IsCompareFinish()
    local compareFinish = Store:Get('world/compareFinish')

    return compareFinish == true
end

function Compare:SetFinish(value)
    Store:Set('world/compareFinish', value)
end

function Compare:GetCompareResult(callback)
    local selectWorld = Store:Get("world/selectWorld")

    if (selectWorld and selectWorld.status == 2) then
        if (type(callback) == "function") then
            callback(JUSTREMOTE)
            return true
        end
    end

    if (not selectWorld or selectWorld.is_zip) then
        self:SetFinish(true)
        MsgBox:Close()
        return false
    end

    if (KeepworkService:IsSignedIn()) then
        self:CompareRevision(callback)
    else
        KeepworkService:LoginWithTokenApi(
            function()
                self:GetCompareResult(callback)
            end
        )
    end
end

function Compare:CompareRevision(callback)
    local foldername = Store:Get("world/foldername")

    local worldDir = Store:Get("world/worldDir")
    local remoteWorldsList = Store:Get("world/remoteWorldsList")
    local remoteRevision = 0

    local currentRevision = WorldRevision:new():init(worldDir.default):Checkout()

    if (not worldDir) then
        return false
    end

    if (self:HasRevision()) then
        local function HandleRevision(data, err)
            if (err == 0 or err == 502) then
                _guihelper.MessageBox(L"网络错误")
                return false
            end

            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            Store:Set("world/currentRevision", currentRevision)
            Store:Set("world/remoteRevision", remoteRevision)

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

        GitService:GetWorldRevision(foldername, HandleRevision)
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

function Compare:HasRevision()
    local worldDir = Store:Get("world/worldDir")

    if (not worldDir or not worldDir.default) then
        return false
    end

    local localFiles = LocalService:LoadFiles(worldDir.default)
    local hasRevision = false

    Store:Set("world/localFiles", localFiles)

    for key, file in ipairs(localFiles) do
        if (string.lower(file.filename) == "revision.xml") then
            hasRevision = true
            break
        end
    end

    return hasRevision
end
