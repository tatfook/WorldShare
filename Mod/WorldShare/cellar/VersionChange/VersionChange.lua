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
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")
local Encoding = commonlib.gettable("commonlib.Encoding")

local VersionChange = NPL.export()

function VersionChange:Init(foldername)
    if (not KeepworkService:IsSignedIn()) then
        _guihelper.MessageBox(L"登录后才能继续")
        return false
    end

    local isEnterWorld = Store:Get("world/isEnterWorld")

    if (isEnterWorld) then
        local worldTag = WorldCommon.GetWorldInfo()

        if(foldername == worldTag.name) then
            _guihelper.MessageBox(L"不能切换当前编辑的世界")
            return
        end
    end

    MsgBox:Show(L"请稍后...")

    self.foldername = foldername

    self:GetVersionSource(
        function()
            MsgBox:Close()
            self:ShowPage()
        end
    )
end

function VersionChange:SetPage()
    Store:Set('page/VersionChange', document:GetPageCtrl())
end

function VersionChange:ClosePage()
    local VersionChangePage = Store:Get('page/VersionChange')

    if (VersionChangePage) then
        VersionChangePage:CloseWindow()
    end
end

function VersionChange:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/VersionChange/VersionChange.html", "VersionChange", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:Remove('page/VersionChange')
    end
end

function VersionChange:GetVersionSource(callback)
    local currentWorld = Store:Get("world/currentWorld")
    local commitId = SyncMain:GetCurrentRevisionInfo() or {}

    if not currentWorld then
        return false
    end

    self.allRevision = commonlib.vector:new()

    KeepworkService:GetWorld(
        Encoding.url_encode(self.foldername or ''),
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

                if (tonumber(currentWorld.revision) == tonumber(item.revision)) then
                    item.isActive = true
                else
                    item.isActive = false
                end

                if (item.commitId == commitId.id) then
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
    local currentWorld = Store:Get("world/currentWorld")
    local foldername = Store:Get("world/foldername")
    local commitId = self.allRevision[index]["commitId"]

    Store:Set("world/commitId", commitId)
    KeepworkService:SetCurrentCommidId(commitId)

    local targetDir = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.default)

    commonlib.Files.DeleteFolder(targetDir)

    MsgBox:Show(L'请稍后...')

    SyncMain:SyncToLocal()

    self:ClosePage()
end