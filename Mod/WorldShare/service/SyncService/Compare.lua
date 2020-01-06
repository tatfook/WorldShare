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
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

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

Compare.REMOTEBIGGER = REMOTEBIGGER
Compare.JUSTLOCAL = JUSTLOCAL
Compare.JUSTREMOTE = JUSTREMOTE
Compare.LOCALBIGGER = LOCALBIGGER
Compare.EQUAL = EQUAL
Compare.compareFinish = true

function Compare:Init(callback)
    if type(callback) ~= 'function' then
        return false
    end

    self.callback = callback

    if not self:IsCompareFinish() then
        return false
    end

    self:SetFinish(false)
    self:GetCompareResult()
end

function Compare:IsCompareFinish()
    return self.compareFinish == true
end

function Compare:SetFinish(value)
    self.compareFinish = value
end

function Compare:GetCompareResult()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or currentWorld.is_zip then
        self:SetFinish(true)
        self.callback(false)

        return false
    end

    if currentWorld.status == 1 then
        CreateWorld:CheckRevision()
        local currentRevision = WorldRevision:new():init(currentWorld.worldpath):Checkout()
        Mod.WorldShare.Store:Set("world/currentRevision", currentRevision)

        self:SetFinish(true)
        self.callback(JUSTLOCAL)
        return true
    end

    if currentWorld.status == 2 then
        self:SetFinish(true)
        self.callback(JUSTREMOTE)
        return true
    end

    self:CompareRevision()
end

-- create revision try times
Compare.createRevisionTimes = 0

function Compare:CompareRevision()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or not currentWorld.worldpath then
        self:SetFinish(true)
        self.callback(false)
        return false
    end

    local currentRevision = WorldRevision:new():init(currentWorld.worldpath):Checkout()
    local remoteRevision = 0

    if self:HasRevision() then
        self.createRevisionTimes = 0

        local function CompareRevision(currentRevision, remoteRevision)
            if remoteRevision == 0 then
                currentWorld.status = 1
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return JUSTLOCAL
            end

            if currentRevision < remoteRevision then
                currentWorld.status = 4
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return REMOTEBIGGER
            end

            if currentRevision > remoteRevision then
                currentWorld.status = 5
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return LOCALBIGGER
            end

            if currentRevision == remoteRevision then
                currentWorld.status = 3
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
                return EQUAL
            end
        end

        if currentWorld and not currentWorld.kpProjectId then
            self:SetFinish(true)
            self.callback(false)
            return true
        end

        local function HandleRevision(data, err)
            if err == 0 or err == 502 then
                self:SetFinish(true)
                self.callback(false)
                return false
            end

            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data) or 0

            self:UpdateSelectWorldInRemoteWorldsList(currentWorld.foldername, remoteRevision)

            Mod.WorldShare.Store:Set("world/currentRevision", currentRevision)
            Mod.WorldShare.Store:Set("world/remoteRevision", remoteRevision)

            local result = CompareRevision(currentRevision, remoteRevision)

            self:SetFinish(true)
            self.callback(result)
        end

        GitService:GetWorldRevision(currentWorld.kpProjectId, true, HandleRevision)
    else
        self.createRevisionTimes = self.createRevisionTimes + 1

        if self.createRevisionTimes > 3 then
            self.createRevisionTimes = 0
            return false
        end

        CreateWorld:CheckRevision()
        self:CompareRevision(callback)
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

    for key, file in ipairs(localFiles) do
        if string.lower(file.filename) == "revision.xml" then
            hasRevision = true
            break
        end
    end

    return hasRevision
end

function Compare:GetCurrentWorldInfo(callback)
    local foldername = Mod.WorldShare.Utils:GetFolderName() or ''
    local currentWorld

    if GameLogic.IsReadOnly() then
        local originWorldPath = ParaWorld.GetWorldDirectory()
        local worldTag = WorldCommon.GetWorldInfo() or {}

        Mod.WorldShare.Store:Set("world/worldTag", worldTag)
        Mod.WorldShare.Store:Set("world/currentWorld", {
            IsFolder = false,
            is_zip = true,
            Title = worldTag.name,
            text = worldTag.name,
            author = "None",
            costTime = "0:0:0",
            filesize = 0,
            foldername = Mod.WorldShare.Utils.GetFolderName(),
            grade = "primary",
            icon = "Texture/3DMapSystem/common/page_world.png",
            ip = "127.0.0.1",
            mode = "survival",
            modifyTime = 0,
            nid = "",
            order = 0,
            preview = "",
            progress = "0",
            size = 0,
            worldpath = originWorldPath,
            kpProjectId = worldTag.kpProjectId
        })
        Mod.WorldShare.Store:Set("world/currentRevision", GameLogic.options:GetRevision())
    else
        local compareWorldList = Mod.WorldShare.Store:Get("world/compareWorldList")
    
        if compareWorldList then
            local searchCurrentWorld = nil
    
            for key, item in ipairs(compareWorldList) do
                if item.foldername == foldername and not item.is_zip then
                    searchCurrentWorld = item
                    break
                end
            end

            if searchCurrentWorld then
                currentWorld = searchCurrentWorld
    
                local worldTag = LocalService:GetTag(currentWorld.worldpath)
    
                Mod.WorldShare.Store:Set("world/worldTag", worldTag)
                Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
            end
        end
    end

    if not currentWorld then
        local originWorldPath = ParaWorld.GetWorldDirectory()
        local worldTag = WorldCommon.GetWorldInfo() or {}

        currentWorld = {
            IsFolder = true,
            is_zip = false,
            Title = worldTag.name,
            text = worldTag.name,
            author = "None",
            costTime = "0:0:0",
            filesize = 0,
            foldername = Mod.WorldShare.Utils.GetFolderName(),
            grade = "primary",
            icon = "Texture/3DMapSystem/common/page_world.png",
            ip = "127.0.0.1",
            mode = "survival",
            modifyTime = 0,
            nid = "",
            order = 0,
            preview = "",
            progress = "0",
            size = 0,
            worldpath = originWorldPath, 
        }

        if worldTag.kpProjectId then
            currentWorld.kpProjectId = worldTag.kpProjectId
        else
            currentWorld.status = 1
        end

        Mod.WorldShare.Store:Set("world/worldTag", worldTag)
        Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)
    end

    if type(callback) == 'function' then
        callback()
    end
end
