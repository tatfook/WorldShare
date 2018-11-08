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
local DeleteWorld = NPL.load("(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local VersionChange = NPL.export()

function VersionChange:Init()
    if (not KeepworkService:IsSignedIn()) then
        _guihelper.MessageBox(L"登录后才能继续")
        return false
    end

    self.foldername = Store:Get("world/foldername")

    local isEnterWorld = Store:Get("world/isEnterWorld")

    if (isEnterWorld) then
        local selectWorld = Store:Get("world/selectWorld")
        local enterWorld = Store:Get("world/enterWorld")

        if(enterWorld.foldername == selectWorld.foldername) then
            _guihelper.MessageBox(L"不能切换当前编辑的世界")
            return
        end
    end

    MsgBox:Show(L"请稍后...")

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
    self.allRevision = commonlib.vector:new()

    GitService:GetCommits(
        self.foldername.base32,
        true,
        function(data, err)
            for key, item in ipairs(data) do
                local path = item.title:gsub("paracraft commit: ", "")

                local date = {}
                for v in string.gmatch(item.created_at, "[^T]+") do
                    date[#date + 1] = v
                end

                if (path == "revision.xml") then
                    local currentRevision = {
                        path = path,
                        commitId = item.id,
                        date = date[1]
                    }

                    self.allRevision:push_back(currentRevision)
                end
            end

            self:GetRevisionContent(callback)
        end
    )
end

local verCountIndex = 1
function VersionChange:GetRevisionContent(callback)
    if (verCountIndex > #self.allRevision) then
        verCountIndex = 1

        if (type(callback) == "function") then
            callback()
        end

        return false
    end

    local currentItem = self.allRevision[verCountIndex]
    local selectWorld = Store:Get("world/selectWorld")
    local commitId = SyncMain:GetCurrentRevisionInfo()

    commitId = commitId and commitId["id"] or ""

    GitService:GetContentWithRaw(
        self.foldername.base32,
        currentItem.path,
        currentItem.commitId,
        function(content)
            if (not content) then
                return false
            end

            currentItem.revision = content
            currentItem.shortId = string.sub(currentItem.commitId, 1, 5)

            if (tonumber(selectWorld.revision) == tonumber(currentItem.revision)) then
                currentItem.isActive = true
            else
                currentItem.isActive = false
            end

            if (currentItem.commitId == commitId) then
                currentItem.isActiveFull = true
            else
                currentItem.isActiveFull = false
            end

            verCountIndex = verCountIndex + 1
            self:GetRevisionContent(callback)
        end
    )
end

function VersionChange:GetAllRevision()
    return self.allRevision
end

function VersionChange:SelectVersion(index)
    local selectWorld = Store:Get("world/selectWorld")
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