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

function Compare:Init(callback)
    local isEnterWorld = Store:Get("world/isEnterWorld")
    local isShowUserConsolePage = UserConsole:IsShowUserConsole()

    self:SetFinish(false)

    if not self:IsCompareFinish() then
        MsgBox:Show(L"请稍后...")
    end

    self:GetCompareResult(
        function(result)
            if (isEnterWorld and not isShowUserConsolePage) then
                if type(callback) == 'function' then
                    callback()
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
    local world

    if Store:Get("world/isEnterWorld") then
        world = Store:Get('world/enterWorld')
    else
        world = Store:Get('world/selectWorld')
    end

    if (world and world.status == 2) then
        if (type(callback) == "function") then
            callback(JUSTREMOTE)
            return true
        end
    end

    if (not world or world.is_zip) then
        self:SetFinish(true)
        MsgBox:Close()
        return false
    end

    self:CompareRevision(callback)
end

function Compare:CompareRevision(callback)
    local foldername
    local worldDir
    local world

    if Store:Get("world/isEnterWorld") then
        foldername = Store:Get("world/enterFoldername")
        worldDir = Store:Get("world/enterWorldDir")
        world = Store:Get('world/enterWorld')
    else
        foldername = Store:Get("world/foldername")
        worldDir = Store:Get("world/worldDir")
        world = Store:Get('world/selectWorld')
    end

    if (not foldername or not worldDir or not world) then
        return false
    end

    local remoteWorldsList = Store:Get("world/remoteWorldsList")
    local remoteRevision = 0
    
    if (self:HasRevision()) then
        local function CompareRevision(currentRevision, remoteRevision)
            if (remoteRevision == 0) then
                return JUSTLOCAL
            end

            if (currentRevision < remoteRevision) then
                return REMOTEBIGGER
            end

            if (currentRevision > remoteRevision) then
                return LOCALBIGGER
            end

            if (currentRevision == remoteRevision) then
                return EQUAL
            end
        end

        local currentRevision = WorldRevision:new():init(worldDir.default):Checkout()

        if (world and not world.kpProjectId) then
            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            Store:Set("world/currentRevision", currentRevision)
            Store:Set("world/remoteRevision", remoteRevision)

            self:SetFinish(true)

            if (type(callback) == "function") then
                callback(CompareRevision(currentRevision, remoteRevision))
            end

            return true
        end

        local function HandleRevision(data, err)
            if (err == 0 or err == 502) then
                _guihelper.MessageBox(L"网络错误")
                return false
            end

            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            self:UpdateSelectWorldInRemoteWorldsList(foldername.utf8, remoteRevision)

            Store:Set("world/currentRevision", currentRevision)
            Store:Set("world/remoteRevision", remoteRevision)

            local result = CompareRevision(currentRevision, remoteRevision)

            self:SetFinish(true)

            if (type(callback) == "function") then
                callback(result)
            end
        end

        GitService:GetWorldRevision(world.kpProjectId, foldername, HandleRevision)
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

function Compare:UpdateSelectWorldInRemoteWorldsList(worldName, remoteRevision)
    local remoteWorldsList = Store:Get('world/remoteWorldsList')

    if not remoteWorldsList or not worldName then
        return false
    end

    for key, item in ipairs(remoteWorldsList) do
        if item.worldName == worldName then
            item.revision = remoteRevision
        end
    end

    Store:Set('world/remoteWorldsList', remoteWorldsList)
end

function Compare:HasRevision()
    local worldDir

    if Store:Get("world/isEnterWorld") then
        worldDir = Store:Get("world/enterWorldDir")
    else
        worldDir = Store:Get("world/worldDir")
    end

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
