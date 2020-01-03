--[[
Title: VersionChange
Author(s):  big
Date: 2018.06.25
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VersionChange = NPL.load("(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua")
------------------------------------------------------------
]]
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
local Encoding = commonlib.gettable("commonlib.Encoding")

local VersionChange = NPL.export()

function VersionChange:Init(foldername)
    if not KeepworkService:IsSignedIn() then
        _guihelper.MessageBox(L"登录后才能继续")
        return false
    end

    local isEnterWorld = Mod.WorldShare.Store:Get("world/isEnterWorld")

    if isEnterWorld then
        local worldTag = WorldCommon.GetWorldInfo()

        if foldername == worldTag.name then
            GameLogic.AddBBS(nil, L"不能切换当前编辑的世界", 3000, "255 0 0")
            return
        end
    end

    Mod.WorldShare.MsgBox:Show(L"请稍后...")

    self.foldername = foldername

    self:GetVersionSource(
        function()
            Mod.WorldShare.MsgBox:Close()
            self:ShowPage()
        end
    )
end

function VersionChange:SetPage()
    Mod.WorldShare.Store:Set('page/VersionChange', document:GetPageCtrl())
end

function VersionChange:ClosePage()
    local VersionChangePage = Mod.WorldShare.Store:Get('page/VersionChange')

    if VersionChangePage then
        VersionChangePage:CloseWindow()
    end
end

function VersionChange:ShowPage()
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/VersionChange/VersionChange.html", "VersionChange", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/VersionChange')
    end
end

function VersionChange:GetVersionSource(callback)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")
    local commitId = SyncMain:GetCurrentRevisionInfo() or {}

    if not currentWorld then
        return false
    end

    self.allRevision = commonlib.vector:new()

    KeepworkServiceWorld:GetWorld(
        self.foldername,
        function(world)
            if type(callback) ~= 'function' then
                return false
            end

            if not world or not world.extra or not world.extra.commitIds then
                callback()
                return false
            end

            for key, item in ipairs(world.extra.commitIds) do
                item.shortId = string.sub(item.commitId, 1, 5)

                if tonumber(currentWorld.revision) == tonumber(item.revision) then
                    item.isActive = true
                else
                    item.isActive = false
                end

                if item.commitId == commitId.id then
                    item.isActiveFull = true
                else
                    item.isActiveFull = false
                end

                self.allRevision:push_back(item)
            end

            callback()
        end
    )
end

function VersionChange:GetAllRevision()
    return self.allRevision
end

function VersionChange:SelectVersion(index)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")
    local commitId = self.allRevision[index]["commitId"]

    local targetDir = format("%s/%s/", Mod.WorldShare.Utils.GetWorldFolderFullPath(), commonlib.Encoding.Utf8ToDefault(currentWorld.foldername))

    commonlib.Files.DeleteFolder(targetDir)
    ParaIO.CreateDirectory(targetDir)

    currentWorld.lastCommitId = commitId
    Mod.WorldShare.Store:Set("world/currentWorld", currentWorld)

    SyncMain:SyncToLocal()
    self:ClosePage()
end