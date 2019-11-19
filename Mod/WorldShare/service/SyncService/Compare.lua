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
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")

local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")

local Compare = NPL.export()

local REMOTEBIGGER = "REMOTEBIGGER"
local JUSTLOCAL = "JUSTLOCAL"
local JUSTREMOTE = "JUSTREMOTE"
local LOCALBIGGER = "LOCALBIGGER"
local EQUAL = "EQUAL"

function Compare:Init(callback)
    local isEnterWorld = Mod.WorldShare.Store:Get("world/isEnterWorld")
    local isShowUserConsolePage = UserConsole:IsShowUserConsole()

    self:SetFinish(false)

    self:GetCompareResult(
        function(result)
            if (isEnterWorld and not isShowUserConsolePage) then
                if type(callback) == 'function' then
                    callback()
                    Mod.WorldShare.MsgBox:Close()
                    return false
                end

                -- if (result == REMOTEBIGGER) then
                --     SyncMain:ShowStartSyncPage()
                -- end

                Mod.WorldShare.MsgBox:Close()
            else
                if (result == JUSTLOCAL) then
                    SyncMain:SyncToDataSource()
                    Mod.WorldShare.MsgBox:Close()
                    return true
                end

                if (result == JUSTREMOTE) then
                    SyncMain:SyncToLocal(callback)
                    return true
                end

                if (result == REMOTEBIGGER or result == LOCALBIGGER or result == EQUAL) then
                    if type(callback) == 'function' then
                        callback(result, function(callback) SyncMain:ShowStartSyncPage(callback, true) end)
                    else
                        SyncMain:ShowStartSyncPage()
                    end

                    Mod.WorldShare.MsgBox:Close()
                    return true
                end
            end
        end
    )
end

function Compare:IsCompareFinish()
    local compareFinish = Mod.WorldShare.Store:Get('world/compareFinish')

    return compareFinish == true
end

function Compare:SetFinish(value)
    Mod.WorldShare.Store:Set('world/compareFinish', value)
end

function Compare:GetCompareResult(callback)
    if not self:IsCompareFinish() then
        Mod.WorldShare.MsgBox:Show(L"请稍后...")
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        Mod.WorldShare.MsgBox:Close()
        return false
    end

    if currentWorld.status == 2 then
        if type(callback) == "function" then
            callback(JUSTREMOTE)
            return true
        end
    end

    if currentWorld.is_zip then
        self:SetFinish(true)
        Mod.WorldShare.MsgBox:Close()
        return false
    end

    self:CompareRevision(callback)
end

-- create revision try times
Compare.createRevisionTimes = 0

function Compare:CompareRevision(callback)
    local foldername = Mod.WorldShare.Store:Get("world/foldername")
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not foldername or not currentWorld or not currentWorld.worldpath then
        return false
    end

    local remoteWorldsList = Mod.WorldShare.Store:Get("world/remoteWorldsList")
    local remoteRevision = 0

    if self:HasRevision() then
        self.createRevisionTimes = 0

        local function CompareRevision(currentRevision, remoteRevision)
            if remoteRevision == 0 then
                return JUSTLOCAL
            end

            if currentRevision < remoteRevision then
                return REMOTEBIGGER
            end

            if currentRevision > remoteRevision then
                return LOCALBIGGER
            end

            if currentRevision == remoteRevision then
                return EQUAL
            end
        end

        local currentRevision = WorldRevision:new():init(currentWorld.worldpath):Checkout()

        if currentWorld and not currentWorld.kpProjectId then
            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            Mod.WorldShare.Store:Set("world/currentRevision", currentRevision)
            Mod.WorldShare.Store:Set("world/remoteRevision", remoteRevision)

            self:SetFinish(true)

            if (type(callback) == "function") then
                callback(CompareRevision(currentRevision, remoteRevision))
            end

            return true
        end

        local function HandleRevision(data, err)
            if err == 0 or err == 502 then
                _guihelper.MessageBox(L"网络错误")
                return false
            end

            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            self:UpdateSelectWorldInRemoteWorldsList(foldername.utf8, remoteRevision)

            Mod.WorldShare.Store:Set("world/currentRevision", currentRevision)
            Mod.WorldShare.Store:Set("world/remoteRevision", remoteRevision)

            local result = CompareRevision(currentRevision, remoteRevision)

            self:SetFinish(true)

            if (type(callback) == "function") then
                callback(result)
            end
        end

        GitService:GetWorldRevision(currentWorld.kpProjectId, true, HandleRevision)
    else
        self.createRevisionTimes = self.createRevisionTimes + 1

        if self.createRevisionTimes > 3 then
            self.createRevisionTimes = 0
            _guihelper.MessageBox(L'创建版本信息失败')
            return false
        end

        CreateWorld:CheckRevision(function()
            self:CompareRevision(callback)
        end)
    end
end

function Compare:UpdateSelectWorldInRemoteWorldsList(worldName, remoteRevision)
    local remoteWorldsList = Mod.WorldShare.Store:Get('world/remoteWorldsList')

    if not remoteWorldsList or not worldName then
        return false
    end

    for key, item in ipairs(remoteWorldsList) do
        if item.worldName == worldName then
            item.revision = remoteRevision
        end
    end

    Mod.WorldShare.Store:Set('world/remoteWorldsList', remoteWorldsList)
end

function Compare:HasRevision()
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    local localFiles = LocalService:LoadFiles(currentWorld and currentWorld.worldpath)
    local hasRevision = false

    Mod.WorldShare.Store:Set("world/localFiles", localFiles)

    for key, file in ipairs(localFiles) do
        if (string.lower(file.filename) == "revision.xml") then
            hasRevision = true
            break
        end
    end

    return hasRevision
end
